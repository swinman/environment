#!/bin/sh
# Dump the 256 terminal colours.  The default output is a compact grid, 16
# numbered swatches per row, each number drawn in its own colour - enough to
# pick a shade at a glance.
#
# --extend prints the older long form: one row per colour, shown as a solid
# block, then as foreground text on the chosen background, then as a
# background under the default foreground.  Its optional argument is that
# background, as a colour index; with no argument the terminal's own
# background is used.  The middle field is the one that answers "is this
# index legible as text here", which is what picking highlight colours
# actually needs.

usage() {
    echo "usage: ${0##*/} [--extend [background colour index 0-255]]" >&2
    exit 1
}

extend=0
if [ "$1" = "--extend" ]; then
    extend=1
    shift
fi

base_color=""
if [ -n "$1" ]; then
    # The background index only means something in the extended per-row
    # output; the grid always draws on the terminal's own background.
    [ "$extend" -eq 1 ] || usage
    case $1 in
        *[!0-9]*) usage ;;
    esac
    [ "$1" -le 255 ] || usage
    base_color=$1
fi

num_colors=256

if [ "$extend" -eq 0 ]; then
    # \033[38;5;Nm rather than tput setaf, to avoid 256 command
    # substitutions for one throwaway grid.
    i=0
    while [ "$i" -lt "$num_colors" ]; do
        printf '\033[38;5;%dm%4d' "$i" "$i"
        [ $(( (i + 1) % 16 )) -eq 0 ] && printf '\033[0m\n'
        i=$((i + 1))
    done
    exit 0
fi

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
