package viz

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type CSV struct {
	config Config
	csv    []string
	path   string
}

func (c *CSV) Init(conf Config) error {
	log.Print("WARNING: CSV mode is only for debug and small DB sizes. Don't use it one production!")
	c.config = conf

	c.path = filepath.Join(workdir, config.CSV.File)

	return c.Update()
}

func (c *CSV) Update() error {
	data, err := ioutil.ReadFile(c.path)
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

func (c *CSV) Watch(changed chan bool, done chan bool) error {
	errs := make(chan error)

	go func() {
		stat, err := os.Stat(c.path)
		if err != nil {
			errs <- err
			return
		}

		for {
			newStat, err := os.Stat(c.path)
			if err != nil {
				errs <- err
				return
			}

			if newStat.ModTime() != stat.ModTime() {
				changed <- true
			}

			stat = newStat

			time.Sleep(1 * time.Second)
		}
	}()

	select {
	case <-done:
		return nil
	case err := <-errs:
		return err
	}
}
