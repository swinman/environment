#!/bin/bash
# provide current counter value and increment
# base for the counter is 32, characters are A-Z 2-7 corresponding to 0-31

# test with
# $ for ((i=0; i<300; i++)); do ./counter.sh; done

# to simply convert to our format call with ./counter [int]

convert() {
    NUM=$1
    CHR_LEN=$2
    BASE=$3
    if [ -z $NUM ]; then
        exit 1
    fi
    if [ -z $CHR_LEN ]; then
        CHR_LEN=4
    fi
    if [ -z "$BASE" ]; then
        BASE=32
    fi

    RSTR=""

    if [ "$DEBUG" == "true" ]; then
        >&2 echo "Number to convert is $NUM"
    fi

    for ((i=$CHR_LEN-1; i>=0; i--))
    do
        BASE_SHIFTED=$(( $BASE ** $i ))
        DIGIT=$(( $NUM / $BASE_SHIFTED ))
        NUM=$(( $NUM - $DIGIT * $BASE_SHIFTED ))
        if [ "$DEBUG" == "true" ]; then
            >&2 echo "$BASE^$i = $BASE_SHIFTED, digit is $DIGIT, remainder is $NUM"
        fi

        if [ $BASE -eq 32 ]; then
            if [ $DIGIT -lt 26 ]; then
                ASCII=$(( 65 + $DIGIT ))        # 'A' is 65
            else
                if [ $DIGIT -gt 31 ]; then
                    DIGIT=$(( $DIGIT % 32 ))
                fi
                ASCII=$(( 50 + $DIGIT - 26 ))   # '2' is 50
            fi
            CHR=$(printf "\x$(printf %x $ASCII)")
        else
            >&2 "Display format for base $BASE is not implemented"
            exit 2
        fi
        RSTR=${RSTR}${CHR}
    done

    if [ $NUM -ne 0 ]; then
        >&2 "Something went wrong, remainder should be zero not $NUM"
        exit 3
    fi

    echo $RSTR
}

COUNT=$1

if [ -z $COUNT ]; then
    SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
    COUNT_FILENAME=$SCRIPTPATH/.ccount
    if [ -f $COUNT_FILENAME ]; then
        COUNT=$(head -c 25 $COUNT_FILENAME)
    else
        COUNT=0
    fi
    NV=$(($COUNT+1))
    echo $NV > $COUNT_FILENAME
fi

DEBUG=false
RV=$(convert $COUNT 4)


echo $RV
