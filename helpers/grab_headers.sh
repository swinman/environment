#!/bin/sh

# this script should grab the header dependencies and move them into
# the src/avr8/ directory

MCU=atxmega32a4u
AVR8_TOOLS_DIR=$toolsdir/avr8-tools
SRC_LIB_DIR=src/avr8

    #grep "^#" \
INC_FILES=$(avr-gcc -E -mmcu=$MCU $AVR8_TOOLS_DIR/avr/include/avr/io.h | \
    grep "avr\/include" \
    | sed 's/^.*"\//\//' | sed 's/".*//' | sort -u | \
    sed '/avr\/io\.h/d' | sed '/^[^\/]/d' )

mkdir -p $SRC_LIB_DIR
mkdir -p $SRC_LIB_DIR/avr

for file in $INC_FILES;
    do
        #echo $file
        #echo $( echo $file | sed "s|$AVR8_TOOLS_DIR/avr/include|$SRC_LIB_DIR|" )
        cp $file $(echo $file | sed "s|$AVR8_TOOLS_DIR/avr/include|$SRC_LIB_DIR|")
done
