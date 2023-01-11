#!/bin/sh

args=$@
>&2 echo "$args ="

python3 -c "import time as t; print(t.strftime('%Y-%m-%d %I:%M:%S %p', t.localtime($args)))"
