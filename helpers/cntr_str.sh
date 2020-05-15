#!/bin/sh

center() {
  termwidth="$(tput cols)"
  padding=$(printf '%0.1s' ={1..500})
  padding="=================================================================="
  printf '%*.*s %s %*.*s\n' 0 "$(((termwidth-2-${#1})/2))" "$padding" "$1" 0 "$(((termwidth-1-${#1})/2))" "$padding"
}

echo $(center "$1")
