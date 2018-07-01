package viz

import (
	// "fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/GeertJohan/go.rice"
	evbus "github.com/asaskevich/EventBus"
)

var bus = evbus.New()

var workdir = ""

func Start(box *rice.Box) {
	configName := "config.toml"

	configDir, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}

	configPath := filepath.Join(configDir, configName)

	conf, err := ReadConfig(configPath)
	if err != nil {
		log.Fatal(err)
	}

	config = conf

	log.Printf("Found config \"%s\"", configPath)

	workdir = filepath.Dir(configPath)

	if err = InitDB(); err != nil {
		log.Fatal(err)
	}

	done := make(chan bool)
	changed := make(chan bool)

	go func() {
		if err := Serve(box); err != nil {
			if conf.Port == 80 {
				log.Print(err, "\nTry to start command from root.")
			} else {
				log.Print(err)
			}
		}
		done <- true
	}()

	go func() {
		err := db.Watch(changed, done)
		if err != nil {
			log.Print(err)
		}
		done <- true
	}()

	for {
		select {
		case <-changed:
			db.Update()
			bus.Publish("update")
		case <-done:
			return
		}
	}
}
