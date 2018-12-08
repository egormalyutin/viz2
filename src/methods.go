package viz

import "log"

// get
type WSGet struct {
	Start int
	End   int
}

var Methods = map[string]func([]byte, string) []byte{
	"get": WrapMethod(func(input *WSGet) (interface{}, error) {
		if input.Start == input.End {
			return "", nil
		}

		if input.Start > input.End {
			input.Start, input.End = input.End, input.Start
		}

		lines, err := db.Get(input.Start, input.End)
		if err != nil {
			return nil, err
		}

		return lines, nil
	}),

	"lines": WrapMethod(func() (interface{}, error) {
		lines, err := db.Lines()
		if err != nil {
			log.Print(err)
			return nil, err
		}
		return lines, nil
	}),
}
