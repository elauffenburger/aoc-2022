awk <input '
    BEGIN {
        i=0;
        max_i=-1;
    }

    $0 ~ /^$/ {
        if (cals[i] > cals[max_i]) {
            max_i = i;
        }

        i++;
    }

    $0 ~ /[0-9]+/{
        cals[i] += +$0;
    }

    END {
        printf("%d: %d\n", max_i, cals[max_i]);
    }
'