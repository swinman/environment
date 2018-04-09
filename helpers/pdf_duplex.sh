#!/bin/sh

# NOTE: In a for loop, if you only want to split names at newlines
# you can set the variable `$  IFS=$'\n'`
# and the for loop will only split at nl instead of nl spaces and tabs

fn=$1
if [ -z "$fn" ]; then
    echo "Join adjacent pages in a pdf into a single landscape page"
    echo "usage: $ ./pdf_duplex.sh fn.pdf"
    echo "outputs 'fn-joined.pdf'"
    exit 1
elif [ ! -f "$fn" ]; then
    echo "File $fn does not exist"
    exit 1
elif [ -z $(echo $fn | sed -e '/.pdf$/!d') ]; then
    echo "File $fn must be a .pdf"
    exit 1
fi

echo "Joining pages in $fn into 2 page per side"
pdfjam --suffix joined --paper letter --landscape --nup 2x1 "$fn"
