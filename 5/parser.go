package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"strings"
)

type crateStack []byte

func (s *crateStack) push(crate byte) {
	*s = append(*s, crate)
}

func (s *crateStack) pop() byte {
	crate := (*s)[len(*s)-1]
	*s = (*s)[:len(*s)-1]

	return crate
}

type crateStacks []crateStack

func (stacks crateStacks) print() {
	var maxStackLen int
	for _, stack := range stacks {
		if len(stack) > maxStackLen {
			maxStackLen = len(stack)
		}
	}

	for i := maxStackLen - 1; i >= 0; i-- {
		for _, stack := range stacks {
			if i < len(stack) {
				fmt.Printf(" [%c]", stack[i])
			} else {
				fmt.Printf("    ")
			}
		}

		fmt.Println()
	}

	for i := 0; i < len(stacks); i++ {
		fmt.Printf("  %d ", i+1)
	}

	fmt.Println()
	fmt.Println()

}

func parseCrateStacks(rdr *bufio.Reader) (crateStacks, error) {
	var stacks crateStacks

	// Read crates lines.
	var crateLines []string
	for {
		line, err := rdr.ReadString('\n')
		if err != nil {
			return nil, fmt.Errorf("error reading crate line: %w", err)
		}

		// We're on the crate stacks line.
		if line[1] == '1' {
			numStacks := int(math.Ceil(float64(len(line)) / 4))
			stacks = make(crateStacks, numStacks)

			// Iterate over all the crate lines from the bottom to the top.
			for i := len(crateLines) - 1; i >= 0; i-- {
				// Iterate over each stack in the crate line and add the crate to the appropriate stack.
				for j := 0; j < numStacks; j++ {
					crate := crateLines[i][(j*4)+1]

					if crate != ' ' {
						stacks[j] = append(stacks[j], crate)
					}
				}
			}

			// Skip the empty line.
			_, err := rdr.ReadString('\n')
			if err != nil {
				return nil, fmt.Errorf("error skipping line after crate stack headers: %w", err)
			}

			break
		}

		// Otherwise, this is just a crate line.
		crateLines = append(crateLines, line)
	}

	return stacks, nil
}

type move struct {
	num, from, to int
}

func (m move) print() {
	fmt.Printf("move %d from %d to %d\n\n", m.num, m.from, m.to)
}

func parseMoves(rdr *bufio.Reader) ([]move, error) {
	var moves []move
	for {
		line, err := rdr.ReadString('\n')
		if err != nil && !errors.Is(err, io.EOF) {
			return nil, fmt.Errorf("error reading move: %w", err)
		}

		if line == "" {
			break
		}

		// Trim newline.
		if line[len(line)-1] == '\n' {
			line = line[:len(line)-1]
		}

		lineParts := strings.Split(line, " ")

		num, err := strconv.ParseInt(lineParts[1], 10, 64)
		if err != nil {
			return nil, fmt.Errorf("error parsing num in move: %w", err)
		}

		from, err := strconv.ParseInt(lineParts[3], 10, 64)
		if err != nil {
			return nil, fmt.Errorf("error parsing from in move: %w", err)
		}

		to, err := strconv.ParseInt(lineParts[5], 10, 64)
		if err != nil {
			return nil, fmt.Errorf("error parsing to in move: %w", err)
		}

		moves = append(moves, move{num: int(num), from: int(from), to: int(to)})
	}

	return moves, nil
}
