#!/bin/sh

args=$@
if [ -z $args ]; then
    args=$(python3 -c "from time import time as t; print(int(t()))")
fi

>&2 echo "$args ="
python3 -c "import time as t; print(t.strftime('%Y-%m-%d %I:%M:%S %p', t.localtime($args)))"
