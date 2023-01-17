#!/usr/bin/env bash

awk <input '
    BEGIN {
        i=0;
    }

    $0 ~ /^$/ {
        i++;
    }

    $0 ~ /[0-9]+/{
        cals[i] += +$0;
    }

    END {
        for (j=0; j<i; j++) {
            printf("%d %d\n", cals[j], j);
        }
    }
' |
    sort -n -r |
    head -n 3 |
    awk '
        BEGIN {
            IFS=" ";
            total=0;
        }

        {
            total += +$1
        }

        END {
            printf("%d\n", total);
        }
    '
