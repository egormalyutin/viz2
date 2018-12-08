package viz

import (
	"fmt"
	"log"
	"net/http"
	"reflect"

	"github.com/GeertJohan/go.rice"
	"github.com/gorilla/websocket"
	jsoniter "github.com/json-iterator/go"
)

var json = jsoniter.ConfigCompatibleWithStandardLibrary

var upgrader = websocket.Upgrader{}

// METHODS
func WrapMethod(handler interface{}) func([]byte, string) []byte {
	h := reflect.ValueOf(handler)
	t := h.Type()

	useArg := false
	var arg reflect.Type
	if t.NumIn() > 0 {
		useArg = true
		arg = t.In(0)
	}

	return func(data []byte, reply string) []byte {
		var result []reflect.Value

		if useArg {
			vr := reflect.New(arg)
			v := vr.Interface()

			err := json.Unmarshal(data, &v)
			if err != nil {
				return []byte(`{"type":"error","data":"\"Invalid JSON\""}`)
			}

			param := reflect.ValueOf(v).Elem()
			result = h.Call([]reflect.Value{param})
		} else {
			result = h.Call([]reflect.Value{})
		}

		ret := result[0].Interface()
		rerr := result[1].Interface()

		if rerr != nil {
			ret = rerr
			reply = "error"
		}

		retResp, err := json.Marshal(ret)
		if err != nil {
			log.Print("Failed to marshal JSON: ", err)
			return []byte(`{"type":"error","data":"\"Server error: cannot marshal JSON\""}`)
		}

		resp, err := json.Marshal(RespWS{reply, string(retResp)})
		if err != nil {
			log.Print("Failed to marshal JSON: ", err)
			return []byte(`{"type":"error","data":"\"Server error: cannot marshal JSON\""}`)
		}

		return resp
	}
}

// WEBSOCKET
type WS struct {
	Type  string `json:"type"`
	Data  string `json:"data"`
	Reply string `json:"reply"`
}

type RespWS struct {
	Type string `json:"type"`
	Data string `json:"data"`
}

func printErr(err error) {
	str := err.Error()
	if str != "websocket: close 1001 (going away)" {
		log.Print(err)
	}
}

func HandleWS(rw http.ResponseWriter, req *http.Request) {
	c, err := upgrader.Upgrade(rw, req, nil)
	if err != nil {
		log.Print("Upgrader error: ", err)
		return
	}
	defer c.Close()

	sub := func() {
		bts := Methods["lines"]([]byte{}, "lines")
		err = c.WriteMessage(websocket.TextMessage, bts)
		if err != nil {
			log.Print(err)
		}
	}

	bus.Subscribe("update", sub)
	defer bus.Unsubscribe("update", sub)

	for {
		_, data, err := c.ReadMessage()
		if err != nil {
			printErr(err)
			break
		}

		var message WS
		err = json.Unmarshal(data, &message)
		if err != nil {
			err = c.WriteMessage(websocket.TextMessage, []byte(`{"type":"error","data":"\"Invalid JSON\""}`))
			if err != nil {
				printErr(err)
				break
			}
			continue
		}

		if message.Reply == "" {
			message.Reply = message.Type
		}

		method, ok := Methods[message.Type]
		if !ok {
			resp := RespWS{"error", "Invalid method \"" + message.Type + "\""}
			bts, err := json.Marshal(resp)
			if err != nil {
				log.Print(err)
				break
			}
			err = c.WriteMessage(websocket.TextMessage, bts)
			if err != nil {
				printErr(err)
				break
			}
			continue
		}

		resp := method([]byte(message.Data), message.Reply)

		err = c.WriteMessage(websocket.TextMessage, resp)
		if err != nil {
			printErr(err)
			break
		}
	}
}

// CONFIG

type ConfigJS struct {
	WS       string     `json:"ws"`
	Language []Language `json:"languages"`
	Format   []string   `json:"format"`
	Plots    []Plot     `json:"plots"`
}

// Send config.js with config data to client
func HandleConfig(rw http.ResponseWriter, req *http.Request) {
	conf := ConfigJS{
		"ws://" + req.Host + "/ws",
		config.Language,
		config.Format,
		config.Plot,
	}
	data, err := json.Marshal(conf)
	if err != nil {
		log.Print(err)
		return
	}

	rw.Write([]byte("window.config = "))
	rw.Write(data)
	rw.Write([]byte(";"))
}

func Serve(box *rice.Box) error {
	http.Handle("/", http.FileServer(box.HTTPBox()))

	http.HandleFunc("/ws", HandleWS)
	http.HandleFunc("/config.js", HandleConfig)

	if config.Port == 80 {
		log.Print("Listening on http://localhost")
	} else {
		log.Printf("Listening on http://localhost:%d", config.Port)
	}

	return http.ListenAndServe(fmt.Sprintf(":%d", config.Port), nil)
}
