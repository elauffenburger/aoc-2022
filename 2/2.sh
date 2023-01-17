#!/usr/bin/env bash

awk <input '
    BEGIN {
        IFS=" "
        score=0;
    }

    function compute_score(them, us) {
        switch(them) {
            case "A":
                switch(us) {
                    case "A":
                        return 1+3;
                        break;

                    case "B":
                        return 2+6;
                        break;

                    case "C":
                        return 3+0;
                        break;
                }
                break;

            case "B":
                switch(us) {
                    case "A":
                        return 1+0;
                        break;

                    case "B":
                        return 2+3;
                        break;

                    case "C":
                        return 3+6;
                        break;
                }
                break;

            case "C":
                switch(us) {
                    case "A":
                        return 1+6;
                        break;

                    case "B":
                        return 2+0;
                        break;

                    case "C":
                        return 3+3;
                        break;
                }
                break;
        }

        return 0;
    }

    {
        move="";
        switch($2) {
            case "X":
                switch($1) {
                    case "A":
                        move="C";
                        break;
                    
                    case "B":
                        move="A";
                        break;

                    case "C":
                        move="B";
                        break;
                }
                break;

            case "Y":
                move=$1;
                break;

            case "Z":
                switch($1) {
                    case "A":
                        move="B";
                        break;
                    
                    case "B":
                        move="C";
                        break;

                    case "C":
                        move="A";
                        break;
                }
                break;
        }
        score+=compute_score($1, move);
    }

    END {
        printf("%d\n", score);
    }
'