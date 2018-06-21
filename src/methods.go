package viz

// get
type WSGet struct {
	Start int
	End   int
}

// lines
type WSLines struct {
	Type string
}

var Methods = map[string]func([]byte) []byte{
	"get": WrapMethod("get", func(input *WSGet) (interface{}, error) {
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
}
