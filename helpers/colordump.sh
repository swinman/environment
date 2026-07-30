#!/bin/zsh
# Dump all 256 terminal colours three ways, to judge them against one
# background.  $1 is that background, as a colour index; with no argument the
# terminal's own background is used.
#
# Each row is one colour, shown as a solid block, then as foreground text on
# the chosen background, then as a background under the default foreground.
# The middle field is the one that answers "is this index legible as text
# here", which is what picking highlight colours actually needs.

if [ -z "$1" ]; then
    base_color=""
elif [ "$1" -ge 0 ] && [ "$1" -le 255 ] 2>/dev/null; then
    base_color=$1
else
    echo "usage: ${0:t} [background colour index 0-255]" >&2
    exit 1
fi

num_colors=256
if [ -n "$base_color" ]; then
    width=16
else
    width=35
fi

reset=$(tput sgr0)$(tput op)
blanks=$(printf "%${width}s")
hashes=${blanks// /#}
sep="${reset} "

for i in $(seq 0 $((num_colors - 1))); do
    line="${reset}$(printf '%03d' $i)"
    line+="${sep}$(tput setab $i)     "                 # empty background
    line+="${sep}$(tput op)$(tput setaf $i)${hashes}"   # foreground, original bg
    line+="${sep}$(tput op)$(tput setab $i)${hashes}"   # background, original fg
    if [ -n "$base_color" ]; then
        line+="${sep}$(tput setab $base_color)$(tput setaf $i)${hashes}"           # fg, selected bg
        line+="${sep}$(tput setaf $base_color)$(tput setab $i)${hashes}${reset}"   # bg, selected fg
    fi
    line+="${reset}"
    print -r -- "${line}${reset}"
done
