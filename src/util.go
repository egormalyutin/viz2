package viz

import (
	"errors"
	"fmt"
	"strings"
)

func mustBeIn(field string, value string, arr []string) error {
	for _, item := range arr {
		if item == value {
			return nil
		}
	}

	jn := []string{}
	for _, item := range arr {
		jn = append(jn, fmt.Sprintf("\"%s\"", item))
	}

	joined := strings.Join(jn[0:len(jn)-1], ", ")
	return errors.New(fmt.Sprintf("Config field \"%s\" can be %s or \"%s\", but got \"%s\"", field, joined, arr[len(jn)-1], value))
}
