package viz

import (
	"errors"
)

type DB interface {
	Init(Config) error
	Get(int, int) (string, error)
	Lines() (int, error)
	Update() error
	Watch(chan bool, chan bool) error
}

// init nil DB
var db DB

func InitDB() error {
	switch config.DB {
	case "csv":
		if config.CSV.File == "" {
			return errors.New("Field \"csv\" must be path to CSV file, but it is not defined")
		}
		config.Format = config.CSV.Format
		db = &CSV{}
		db.Init(config)
	}
	return nil
}
