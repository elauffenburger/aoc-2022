package main

import (
	"fmt"
	"os"
)

func main() {
	var debug bool

	args := os.Args
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "-d":
			debug = true
		}
	}

	result, err := two(debug)
	if err != nil {
		panic(err)
	}

	fmt.Printf("%s\n", result)
}
