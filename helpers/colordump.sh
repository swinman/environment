#!/bin/sh
# Dump all 256 terminal colours three ways, to judge them against one
# background.  $1 is that background, as a colour index; with no argument the
# terminal's own background is used.
#
# Each row is one colour, shown as a solid block, then as foreground text on
# the chosen background, then as a background under the default foreground.
# The middle field is the one that answers "is this index legible as text
# here", which is what picking highlight colours actually needs.

usage() {
    echo "usage: ${0##*/} [background colour index 0-255]" >&2
    exit 1
}

base_color=""
if [ -n "$1" ]; then
    case $1 in
        *[!0-9]*) usage ;;
    esac
    [ "$1" -le 255 ] || usage
    base_color=$1
fi

num_colors=256
if [ -n "$base_color" ]; then
    width=16
else
    width=34
fi

reset=$(tput sgr0)$(tput op)
hashes=$(printf "%${width}s" | tr ' ' '#')
sep="${reset} "

i=0
while [ "$i" -lt "$num_colors" ]; do
    line="${reset}$(printf '%03d' "$i")"
    line="${line}${sep}$(tput setab "$i")     "                # empty background
    line="${line}${sep}$(tput op)$(tput setaf "$i")${hashes}"  # foreground, original bg
    line="${line}${sep}$(tput op)$(tput setab "$i")${hashes}"  # background, original fg
    if [ -n "$base_color" ]; then
        line="${line}${sep}$(tput setab "$base_color")$(tput setaf "$i")${hashes}"  # fg, selected bg
        line="${line}${sep}$(tput setaf "$base_color")$(tput setab "$i")${hashes}"  # bg, selected fg
    fi
    printf '%s%s\n' "$line" "$reset"
    i=$((i + 1))
done
