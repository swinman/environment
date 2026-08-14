#!/bin/sh
#
# shconf_maroon.sh - repaint the CURRENT terminal, not the profile.
#
# VTE (gnome-terminal), xterm, kitty and alacritty all take OSC 10 and OSC 11
# to set foreground and background for the running terminal.  Nothing reaches
# dconf, so the change lasts exactly as long as the window does and no profile
# has to be created to try a color out.
#
#     ./shconf_maroon.sh            repaint this terminal
#     ./shconf_maroon.sh reset      hand it back to the profile
#     . ./shconf_maroon.sh          same, sourced from an rc file
#
# Override either color to taste-test without editing the file:
#
#     MAROON_BG='#200606' ./shconf_maroon.sh
#
# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %

# Uncomment one.  All three are Ubuntu's aubergine (#300A24) rotated to hue 0
# at the same saturation, then stepped down in luminance.
#MAROON_BG=${MAROON_BG:-'#300A0A'}   # lightness-matched to aubergine
MAROON_BG=${MAROON_BG:-'#280808'}   # about a quarter darker
#MAROON_BG=${MAROON_BG:-'#200606'}   # darker again

# Uncomment one.  Contrast, not hue, is what decides whether text reads against
# a ground this dark, so the lighter values are the clearer ones even where
# they carry more of a cast.
#MAROON_FG=${MAROON_FG:-'#d0cfcc'}   # GNOME default, neutral-warm
MAROON_FG=${MAROON_FG:-'#d3d7cf'}   # Tango white, faint green cast
#MAROON_FG=${MAROON_FG:-'#e6e6e2'}   # lighter again, if the above reads dim

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #

# maroon_supported
#
# An OSC sequence written where nothing will interpret it is corruption, not a
# no-op.  The tty test is what keeps this safe to source from an rc file that
# also runs for scp and rsync sessions.
maroon_supported() {
    if [ ! -t 1 ]; then
        return 1
    fi
    case "$TERM" in
        screen*|tmux*)
            # A multiplexer swallows OSC unless it is wrapped in that
            # multiplexer's own passthrough, which differs between the two.
            # Silent rather than a warning: this is sourced from .bashrc, so a
            # message here lands in every pane on every new shell.
            return 1
            ;;
        dumb|'')
            return 1
            ;;
    esac
    return 0
}

maroon_apply() {
    printf '\033]11;%s\007' "$MAROON_BG"
    printf '\033]10;%s\007' "$MAROON_FG"
}

# maroon_reset
#
# 110 and 111 are the reset counterparts of 10 and 11: the terminal goes back
# to whatever its profile says, which is not the same as setting the aubergine
# values back by hand.
maroon_reset() {
    printf '\033]111\007'
    printf '\033]110\007'
}

# --------------------- SETUP SCRIPT --------------------- #
# One conditional and no early return, so the file behaves the same whether it
# is executed or sourced.  `exit` would kill an interactive shell that sourced
# it, and `return` is an error in a script that was executed.
if maroon_supported; then
    case "$1" in
        reset|--reset|off) maroon_reset ;;
        *)                 maroon_apply ;;
    esac
fi

unset -f maroon_supported maroon_apply maroon_reset
