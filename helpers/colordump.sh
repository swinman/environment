#!/bin/zsh
# Dump all 256 terminal colours three ways, to judge them against one
# background.  $1 is that background, as a colour index; with no argument the
# terminal's own background is used.
#
# Each row is one colour, shown as a solid block, then as foreground text on
# the chosen background, then as a background under the default foreground.
# The middle field is the one that answers "is this index legible as text
# here", which is what picking highlight colours actually needs.

if [ -n "$1" ]; then
    if [ "$1" -lt 0 ] || [ "$1" -gt 255 ] 2>/dev/null; then
        echo "usage: ${0:t} [background colour index 0-255]" >&2
        exit 1
    fi
    base_bg=$(tput setab $1)
else
    base_bg=$(tput op)
fi

num_colors=256
width=25

reset=$(tput sgr0)
blanks=$(printf "%${width}s")
hashes=${blanks// /#}
sep="${reset}${base_bg} "

for i in $(seq 0 $((num_colors - 1))); do
    line="${reset}${base_bg}$(printf '%03d' $i)"
    line+="${sep}$(tput setab $i)${blanks}"
    line+="${sep}$(tput setaf $i)${hashes}"
    line+="${sep}$(tput setab $i)${hashes}"
    print -r -- "${line}${reset}"
done
