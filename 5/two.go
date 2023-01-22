package main

import (
	"bufio"
	"fmt"
	"os"
)

func two(debug bool) (string, error) {
	rdr := bufio.NewReader(os.Stdin)

	// Parse stacks.
	stacks, err := parseCrateStacks(rdr)
	if err != nil {
		return "", fmt.Errorf("error reading crate stacks: %w", err)
	}

	// Parse moves.
	moves, err := parseMoves(rdr)
	if err != nil {
		return "", fmt.Errorf("error reading moves: %w", err)
	}

	// Perform moves.
	for _, move := range moves {
		// Print debug info.
		if debug {
			stacks.print()
			move.print()
		}

		tempStack := make(crateStack, move.num)
		for i := 0; i < move.num; i++ {
			crate := stacks[move.from-1].pop()
			tempStack.push(crate)
		}

		for i := 0; i < move.num; i++ {
			crate := tempStack.pop()
			stacks[move.to-1].push(crate)
		}
	}

	if debug {
		stacks.print()
	}

	// Find crates on top of each stack.
	var result string
	for _, stack := range stacks {
		if len(stack) > 0 {
			result = fmt.Sprintf("%s%c", result, stack[len(stack)-1])
		}
	}

	return result, nil
}
