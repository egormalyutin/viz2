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
func WrapMethod(name string, handler interface{}) func([]byte) []byte {
	h := reflect.ValueOf(handler)
	t := h.Type()

	useArg := false
	var arg reflect.Type
	if t.NumIn() > 0 {
		useArg = true
		arg = t.In(0)
	}

	return func(data []byte) []byte {
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
			name = "error"
		}

		retResp, err := json.Marshal(ret)
		if err != nil {
			log.Print("Failed to marshal JSON: ", err)
			return []byte(`{"type":"error","data":"\"Server error: cannot marshal JSON\""}`)
		}

		resp, err := json.Marshal(WS{name, string(retResp)})
		if err != nil {
			log.Print("Failed to marshal JSON: ", err)
			return []byte(`{"type":"error","data":"\"Server error: cannot marshal JSON\""}`)
		}

		return resp
	}
}

// WEBSOCKET
type WS struct {
	Type string `json:"type"`
	Data string `json:"data"`
}

func HandleWS(rw http.ResponseWriter, req *http.Request) {
	c, err := upgrader.Upgrade(rw, req, nil)
	if err != nil {
		log.Print("Upgrader error: ", err)
		return
	}
	defer c.Close()

	for {
		_, data, err := c.ReadMessage()
		if err != nil {
			log.Print(err)
			break
		}

		var message WS
		err = json.Unmarshal(data, &message)
		if err != nil {
			err = c.WriteMessage(websocket.TextMessage, []byte(`{"type":"error","data":"\"Invalid JSON\""}`))
			if err != nil {
				log.Print(err)
				break
			}
			continue
		}

		method, ok := Methods[message.Type]
		if !ok {
			resp := WS{"error", "Invalid method \"" + message.Type + "\""}
			bts, err := json.Marshal(resp)
			if err != nil {
				log.Print(err)
				break
			}
			err = c.WriteMessage(websocket.TextMessage, bts)
			if err != nil {
				log.Print(err)
				break
			}
			continue
		}

		resp := method([]byte(message.Data))

		err = c.WriteMessage(websocket.TextMessage, resp)
		if err != nil {
			log.Print(err)
			break
		}
	}
}

// CONFIG

type ConfigJS struct {
	WS       string     `json:"ws"`
	Language []Language `json:"languages"`
	Format   []string   `json:"format"`
}

// Send config.js with config data to client
func HandleConfig(rw http.ResponseWriter, req *http.Request) {
	conf := ConfigJS{
		"ws://" + req.Host + "/ws",
		config.Language,
		config.Format,
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
