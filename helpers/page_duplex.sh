#!/bin/sh

# NOTE: In a for loop, if you only want to split names at newlines
# you can set the variable `$  IFS=$'\n'`
# and the for loop will only split at nl instead of nl spaces and tabs

echo "Joining pages in $1 into 2 page per side"
pdfjam --suffix joined --paper letter --landscape --nup 2x1 $1
