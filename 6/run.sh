#!/usr/bin/env bash

clang main.c utils.c -o ./build/out && ./build/out <input "$@"