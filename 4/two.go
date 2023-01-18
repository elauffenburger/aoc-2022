package main

import (
	"bufio"
	"errors"
	"io"
	"os"
)

func two() (int, error) {
	rdr := bufio.NewReader(os.Stdin)

	numOverlapping := 0
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

		if assignments.first.overlaps(assignments.second) {
			numOverlapping += 1
		}
	}

	return numOverlapping, nil
}
