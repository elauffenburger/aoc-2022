#!/usr/bin/env bash

set -o errexit -o nounset

mkdir build || true
zig build-exe main.zig -femit-bin=./build/out -freference-trace
./build/out 2>&1 "$@"