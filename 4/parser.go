package main

import (
	"strconv"
	"strings"
)

type assignments struct {
	first, second assignment
}

type assignment struct {
	start, end int
}

func (a assignment) contains(other assignment) bool {
	return (a.start <= other.start && a.end >= other.end) ||
		(other.start <= a.start && other.end >= a.end)
}

func (a assignment) overlaps(other assignment) bool {
	return a.start <= other.end && other.start <= a.end
}

func parseAssignments(str string) (assignments, error) {
	parts := strings.Split(str, ",")

	first, err := parseAssignment(parts[0])
	if err != nil {
		return assignments{}, err
	}

	second, err := parseAssignment(parts[1])
	if err != nil {
		return assignments{}, err
	}

	return assignments{first, second}, nil
}

func parseAssignment(str string) (assignment, error) {
	parts := strings.Split(str, "-")

	start, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return assignment{}, err
	}

	end, err := strconv.ParseInt(parts[1], 10, 64)
	if err != nil {
		return assignment{}, err
	}

	return assignment{int(start), int(end)}, nil
}
