package viz

import (
	"errors"
	"path/filepath"
)

type DB interface {
	Init(Config) error
	Get(int, int) (string, error)
	Lines() (int, error)
}

// init nil DB
var db DB

func InitDB(workdir string) error {
	switch config.DB {
	case "csv":
		if config.CSV == "" {
			return errors.New("Field \"csv\" must be path to CSV file, but it is not defined")
		}
		config.CSV = filepath.Join(workdir, config.CSV)
		db = &CSV{}
		db.Init(config)
	}
	return nil
}
