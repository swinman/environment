#!/bin/sh

# may need to install wmctrl
# the the window id of the current window (obviously some shell)

# ./resize.sh 80 24     # default new window
# ./resize.sh 85 50     # viq
# ./resize.sh 165 50    # vidq

COLS=$1
LINES=$2

if [ -z "$COLS" ]; then
    COLS=85
fi

if [ -z $LINES ]; then
    LINES=50
fi

get_terminal_id() {
    IDS=$(wmctrl -lx | sed 's/^\([^ ]*\).*/\1/')
    for id in $IDS; do
        has=$(xprop -id $id | grep STATE_FOCUSED | wc -l)
        if [ $has -eq 1 ]; then
            echo $id
        fi
    done
}

get_upper_left() {
    TID=0x$(echo $1 | sed 's/^0x0*//')
    SHAPE=$(xwininfo -shape -id $TID)
    ULX=$(xwininfo -shape -id $TID | grep 'Absolute upper-left X' | sed 's/[^:]*: *//')
    ULY=$(xwininfo -shape -id $TID | grep 'Absolute upper-left Y' | sed 's/[^:]*: *//')
#    xwininfo -shape -id $TID 1>&2
    ULY=$(( ULY - 30 ))
    echo "$ULX,$ULY"
}

NO_XTERM=$(xprop -root > /dev/null 2> /dev/null; echo $?)

NO_DISPLAY=$(if [ -z "$DISPLAY" ]; then echo 1; else echo 0; fi)
NO_WMCTRL=$(wmctrl -h > /dev/null 2> /dev/null; echo $?)

#echo "no xterm $NO_XTERM and no wmctrl $NO_WMCTRL"



#wmctrl -h > /dev/null 2> /dev/null && TMP=$?
#if [ $? -eq 0 ]; then
#    alias viq='wmctrl -r :ACTIVE: -e 0,0,0,609,752'
#    alias vidq='wmctrl -r :ACTIVE: -e 0,0,0,1169,752'
#else
#    alias viq='vi -c "set columns=85" -c "set lines=50" -c q'
#    alias vidq='vi -c "set columns=165" -c "set lines=50" -c q'
#fi


#if [ -z NO ] && [ $NO_XTERM -eq 0 ] && [ $NO_WMCTRL -eq 0 ]; then
if [ $NO_DISPLAY -eq 0 ] && [ $NO_WMCTRL -eq 0 ]; then
    TID=$(get_terminal_id)
    TOPLEFT=$(get_upper_left $TID)
#    echo "TID is $TID"
#    echo "TOPLEFT is $TOPLEFT"
#    LINE=$(wmctrl -lG | grep $TID)
#    TOPLEFT=$(echo $LINE | sed 's/[^ ]* *[0-9]* *\([0-9]*\) *\([0-9]*\).*/\1,\2/')
#    echo "LINE is $LINE"
    WID=$(( 609 + 7*$COLS - 7*85 ))
    HGT=$(( 752 + 15*$LINES - 15*50 ))
    wmctrl -r :ACTIVE: -e 0,$TOPLEFT,$WID,$HGT # -e 0,0,0,1169,752'
else
    vim -c "set columns=$COLS" -c "set lines=$LINES" -c q
    resize > /tmp/resize
    sh /tmp/resize
fi
