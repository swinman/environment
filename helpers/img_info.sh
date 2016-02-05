#!/bin/sh

# move images into year/year-month directory

for file in $(find . -iname "*.jpg"); do
    yr_mo=$(identify -verbose $file | grep DateTimeOriginal | sed 's/.*Original: \(....\):\(..\).*/\1-\2/')
    mkdir -p $yr_mo
    mv $file $yr_mo
done
