package main

import "fmt"

func main() {
	result, err := two()
	if err != nil {
		panic(err)
	}

	fmt.Printf("%d\n", result)
}
