package viz

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"strings"
)

type CSV struct {
	config Config
	csv    []string
}

func (c *CSV) Init(conf Config) error {
	log.Print("WARNING: CSV mode is only for debug and small DB sizes. Don't use it one production!")
	c.config = conf

	data, err := ioutil.ReadFile(c.config.CSV)
	if err != nil {
		return err
	}

	c.csv = strings.Split(string(data), "\n")

	return nil
}

func (c *CSV) Lines() (int, error) {
	return len(c.csv), nil
}

func (c *CSV) Get(start int, end int) (sl string, err error) {
	lines := c.csv[start:end]
	defer func() {
		if recover() != nil {
			err = errors.New(fmt.Sprintf("Cannot get data between lines %d and %d", start, end))
		}
	}()
	sl = strings.Join(lines, "\n")
	return
}
