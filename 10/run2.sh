#!/usr/bin/env bash

cargo build --bin ten && ./target/debug/ten "$@"