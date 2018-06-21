package main

import (
	"github.com/GeertJohan/go.rice"
	viz "github.com/malyutinegor/viz2/src"
)

func main() {
	viz.Start(rice.MustFindBox("public"))
}
