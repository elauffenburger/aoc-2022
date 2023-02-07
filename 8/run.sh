#!/usr/bin/env bash

go build -o build/cmd main.go  && ./build/cmd "$@"