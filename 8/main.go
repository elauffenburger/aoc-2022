package main

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"time"

	"github.com/fatih/color"
)

func main() {
	if err := emain(); err != nil {
		panic(err)
	}
}

func emain() error {
	debug := false
	for i := 1; i < len(os.Args); i++ {
		if os.Args[i] == "-d" {
			debug = true

			i++
			if i >= len(os.Args) {
				break
			}

			sleep, err := strconv.ParseInt(os.Args[i], 10, 32)
			if err == nil {
				fmt.Println("waiting...")
				time.Sleep(time.Duration(sleep) * time.Second)
			}
		}
	}

	rows, err := readRows()
	if err != nil {
		return err
	}

	one(rows, debug)

	return nil
}

func one(rows rows, debug bool) {
	numVisible := 0
	for rowNum, row := range rows {
		for colNum := range row {
			if debug {
				rows.print(rowNum, colNum)
			}

			visible := rows.isVisible(rowNum, colNum)
			if visible {
				numVisible++
			}

			if debug {
				fmt.Printf("visible: %v\n", visible)
			}
		}
	}

	fmt.Printf("%d\n", numVisible)
}

type row []int
type rows []row

func (r rows) isVisible(rowNum, colNum int) bool {
	// Check if this is an edge tree.
	{
		// Top.
		if rowNum == 0 ||
			// Bottom.
			rowNum == len(r)-1 ||
			// Left.
			colNum == 0 ||
			// Right.
			colNum == len(r[rowNum])-1 {
			return true
		}
	}

	height := r[rowNum][colNum]

	// Check if this tree is visible in row.
	{
		// Check if this tree is visible from the left.
		if isMaxExclusive(height, r[rowNum][0:colNum]) {
			return true
		}

		// Check if this tree is visible from the right.
		if isMaxExclusive(height, r[rowNum][colNum+1:]) {
			return true
		}
	}

	// Check if this tree is visible in column.
	{
		colSlice := r.colSlice(colNum)

		// Check if this tree is visible from the top.
		if isMaxExclusive(height, colSlice[0:rowNum]) {
			return true
		}

		// Check if this tree is visible from the bottom.
		if isMaxExclusive(height, colSlice[rowNum+1:]) {
			return true
		}
	}

	return false
}

func (r rows) colSlice(col int) []int {
	slice := make([]int, 0, len(r))
	for _, row := range r {
		slice = append(slice, row[col])
	}

	return slice
}

func isMaxExclusive(needle int, haystack []int) bool {
	for _, other := range haystack {
		if other >= needle {
			return false
		}
	}

	return true
}

func (r rows) print(rowNum, colNum int) {
	for i, row := range r {
		for j, height := range row {
			if i == rowNum && j == colNum {
				fmt.Print(color.RedString("%d ", height))
			} else {
				fmt.Printf("%d ", height)
			}
		}

		fmt.Println()
	}
}

func readRows() (rows, error) {
	var rows rows

	rdr := bufio.NewReader(os.Stdin)
	for {
		line, _, err := rdr.ReadLine()
		if errors.Is(err, io.EOF) {
			return rows, nil
		}

		if err != nil {
			return nil, err
		}

		var row = make(row, 0, len(line))
		for _, c := range line {
			height, err := strconv.ParseInt(string(c), 10, 8)
			if err != nil {
				return nil, err
			}

			row = append(row, int(height))
		}

		rows = append(rows, row)
	}
}
