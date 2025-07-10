#!/bin/sh

newpath=$1

if [ -z "$newpath" ]; then
    newdir=$(pwd)
elif [ -d "$newpath" ]; then
    newdir=$(realpath $newpath)
else
    newdir=$(realpath $(pwd)/$1)
fi

echo "adding $newdir to pythonpath"

if [ -z "$PYTHONPATH" ]; then
    export PYTHONPATH=$newdir
else
    export PYTHONPATH=$newdir:$PYTHONPATH
fi
