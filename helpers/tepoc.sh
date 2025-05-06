#!/bin/sh

args=$@
if [ -z $args ]; then
    args=$(python3 -c "from time import time as t; print(int(t()))")
fi

#>&2 echo "$args "
echo "$args "
python3 -c "import time, sys; print(time.strftime('= %Y-%m-%d %I:%M:%S %p', time.localtime(int(\"$args\"))), file=sys.stderr)"
