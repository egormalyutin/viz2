package viz

import (
	"errors"
	"io/ioutil"
	"strings"

	"github.com/BurntSushi/toml"
	// "github.com/alecthomas/kingpin"
)

type Config struct {
	DB       string
	CSV      CSVConfig
	Port     int
	Language []Language
	Format   []string
}

type CSVConfig struct {
	File   string
	Format []string
}

type Language struct {
	Language string   `json:"language"`
	Headers  []string `json:"headers"`
}

// empty config at start
var config = Config{}

func ParseConfig(path string, data []byte) (Config, error) {
	var conf Config
	if err := toml.Unmarshal(data, &conf); err != nil {
		return conf, err
	}

	// lint
	conf.DB = strings.ToLower(conf.DB)
	if err := mustBeIn("db", conf.DB, []string{"csv", "mongodb"}); err != nil {
		return conf, err
	}

	if conf.Port == 0 {
		return conf, errors.New("Field \"port\" is not defined")
	}

	return conf, nil
}

func ReadConfig(path string) (Config, error) {
	data, err := ioutil.ReadFile(path)
	if err != nil {
		return Config{}, err
	}

	conf, err := ParseConfig(path, data)
	if err != nil {
		return conf, err
	}

	return conf, nil
}
