#!/bin/sh

args=$@
>&2 echo "$args ="

python3 -c "from math import *; print($args)"
