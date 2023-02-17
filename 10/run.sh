#!/usr/bin/env bash

cargo build --bin ten && ./target/debug/ten "$@" |
    rg --pcre2 'before: (?:.*?) cycle: ([0-9]+), (?:.*?) x: ([0-9]+)' -o -r '$1 $2' | 
    rg '^(?:20|60|100|140|180|220) ([0-9]+)' | 
    awk -F' ' '
        {
            str=($1*$2); 
            sum+=str;
            printf("@%d: %d -> %d\n", $1, $2, str)
        } 
        
        END { 
            printf("total: %d\n", sum); 
        }
    '
