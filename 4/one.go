package main

import (
	"bufio"
	"errors"
	"io"
	"os"
)

func one() (int, error) {
	rdr := bufio.NewReader(os.Stdin)

	numFullyContained := 0
	for {
		line, err := rdr.ReadString('\n')
		if errors.Is(err, io.EOF) && line == "" {
			break
		}

		// Strip the newline.
		if line[len(line)-1] == '\n' {
			line = line[0 : len(line)-1]
		}

		assignments, err := parseAssignments(line)
		if err != nil {
			return 0, err
		}

		if assignments.first.contains(assignments.second) {
			numFullyContained += 1
		}
	}

	return numFullyContained, nil
}
