package main

import "fmt"

func main() {
	result, err := one()
	if err != nil {
		panic(err)
	}

	fmt.Printf("%s\n", result)
}
