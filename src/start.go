package viz

import (
	// "fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/GeertJohan/go.rice"
)

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

	if err = InitDB(filepath.Dir(configPath)); err != nil {
		log.Fatal(err)
	}

	if err = Serve(box); err != nil {
		if conf.Port == 80 {
			log.Fatal(err, "\nTry to start command from root.")
		} else {
			log.Fatal(err)
		}
	}
}
