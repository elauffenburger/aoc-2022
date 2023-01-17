#!/usr/bin/env bash

awk <input '
    BEGIN {
        IFS=" "
        score=0;
    }

    {
        round_score=0;
        switch($1) {
            case "A":
                switch($2) {
                    case "X":
                        round_score=1+3;
                        break;

                    case "Y":
                        round_score=2+6;
                        break;

                    case "Z":
                        round_score=3+0;
                        break;
                }
                break;

            case "B":
                switch($2) {
                    case "X":
                        round_score=1+0;
                        break;

                    case "Y":
                        round_score=2+3;
                        break;

                    case "Z":
                        round_score=3+6;
                        break;
                }
                break;

            case "C":
                switch($2) {
                    case "X":
                        round_score=1+6;
                        break;

                    case "Y":
                        round_score=2+0;
                        break;

                    case "Z":
                        round_score=3+3;
                        break;
                }
                break;
        }

        score+=round_score;
    }

    END {
        printf("%d\n", score);
    }
'