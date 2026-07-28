# config_common.sh - helpers shared by the config_*.sh scripts.
#
# Sourced, not executed:
#
#     ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
#     . "$ENVDIR/config_common.sh"
#
# $ENVDIR is normally exported by config_shell.sh.  Scripts fall back to their
# own directory so each stays runnable on its own before config_shell.sh has
# been run for the first time on a new machine.  That fallback replaced the
# older habit of deriving paths from $0 or ${BASH_SOURCE[0]} at each use site.

# link_config <path-relative-to-ENVDIR> <destination>
#
# Point a destination at a file or directory in the repo, so it tracks the repo
# instead of being a copy.  Anything real already at the destination is backed
# up rather than clobbered.
link_config() {
    _lc_src="$ENVDIR/$1"
    _lc_dst="$2"

    if [ ! -e "$_lc_src" ]; then
        echo "  WARNING: $_lc_src missing in repo, skipping $_lc_dst"
        return 1
    fi

    if [ -L "$_lc_dst" ]; then
        # Compare the target rather than just testing "is a symlink": a link
        # left over from an older layout should be repaired, not kept.
        if [ "$(readlink "$_lc_dst")" = "$_lc_src" ]; then
            echo "  $_lc_dst already linked"
            return 0
        fi
        echo "  relinking $_lc_dst (was $(readlink "$_lc_dst"))"
        rm -f "$_lc_dst"
    elif [ -e "$_lc_dst" ]; then
        _lc_bak="$_lc_dst.bak.$(date +%Y%m%d%H%M%S)"
        mv "$_lc_dst" "$_lc_bak"
        echo "  backed up $_lc_dst -> $_lc_bak"
    fi

    ln -s "$_lc_src" "$_lc_dst"
    echo "  linked $_lc_dst -> $_lc_src"
}

# retire_path <path> <graveyard-directory>
#
# Move something obsolete out of the way instead of deleting it, so a bad
# guess about what is still wanted is recoverable.
retire_path() {
    [ -e "$1" ] || return 0
    mkdir -p "$2"
    _rp_dst="$2/$(basename "$1")"
    if [ -e "$_rp_dst" ]; then
        _rp_dst="$_rp_dst.$(date +%Y%m%d%H%M%S)"
    fi
    mv "$1" "$_rp_dst"
    echo "  moved $1 aside to $_rp_dst"
}

# clone_or_pull <url> <directory>
#
# Fetch a repo, or bring an existing checkout up to date.  --ff-only so a
# checkout that has somehow diverged fails loudly instead of quietly growing a
# merge commit in someone else's repository.
clone_or_pull() {
    _cp_url="$1"
    _cp_dir="$2"
    _cp_name=$(basename "$_cp_dir")

    if [ -d "$_cp_dir/.git" ]; then
        echo "  updating $_cp_name"
        git -C "$_cp_dir" pull --ff-only --quiet ||
            echo "  WARNING: pull failed in $_cp_dir - diverged or dirty?"
    elif [ -e "$_cp_dir" ]; then
        echo "  WARNING: $_cp_dir exists but is not a git checkout, leaving it"
    else
        echo "  cloning $_cp_name"
        git clone --quiet "$_cp_url" "$_cp_dir"
    fi
}

# --------------------- unattended runs --------------------- #
# A full run takes tens of minutes and its questions are scattered through it,
# so walking away means coming back to a script parked on a prompt raised long
# after the work started.  The two helpers below let all_config.sh take the
# sudo password and every answer before any of the work begins.

# prime_sudo
#
# Validate sudo once and hold the timestamp open for the rest of the run.
# sudo records it per (user, tty) and macOS expires it after five minutes, so
# a background loop re-validates rather than letting a later `sudo installer`
# stop for a password an hour in.
#
# The config_*.sh scripts run as children on the same tty, so they inherit the
# validated timestamp and need no priming of their own.
prime_sudo() {
    if ! sudo -v; then
        echo "  WARNING: sudo could not be validated.  Steps needing root will"
        echo "  prompt when reached, or fail outright on a non-admin account."
        return 1
    fi
    # kill -0 on the parent so the loop cannot outlive a script that died
    # without running its EXIT trap.  Breaking on a failed -n also stops it
    # if the timestamp is revoked from elsewhere.
    #
    # The sleep runs as its own job with the loop waiting on it, rather than
    # inline, so the TERM end_sudo sends is handled between refreshes instead
    # of orphaning a sleep that outlives the run.  $$ inside the subshell is
    # still the parent's pid, which is what the liveness check wants.
    (
        trap 'kill $_ka_sleep 2>/dev/null; exit 0' TERM
        while kill -0 "$$" 2>/dev/null; do
            sudo -n true 2>/dev/null || break
            sleep 60 &
            _ka_sleep=$!
            wait $_ka_sleep
        done
    ) &
    _sudo_keepalive=$!
    trap 'end_sudo' EXIT
    trap 'end_sudo; exit 130' INT
    trap 'end_sudo; exit 143' TERM
}

# end_sudo
#
# Stop the keepalive.  Called from the traps prime_sudo installs; safe to call
# when priming never happened or has already been cleaned up.
end_sudo() {
    [ -n "$_sudo_keepalive" ] && kill "$_sudo_keepalive" 2>/dev/null
    _sudo_keepalive=
}

# ask_once <var-name> <prompt>
#
# Prompt only when there is no answer yet, leaving the result in the named
# variable.  A script run on its own still asks its own questions; the same
# script run from all_config.sh stays silent, because $CONFIG_PROMPTS_DONE
# says the question was already put.
#
# That flag is what makes an empty answer stick.  Several of these prompts
# treat ENTER as "leave it alone", so testing the variable alone would ask
# again every time the answer was deliberately blank.
ask_once() {
    _ao_var="$1"
    eval "[ -n \"\${$_ao_var}\" ]" && return 0
    [ -n "$CONFIG_PROMPTS_DONE" ] && return 0
    printf '%s' "$2"
    read _ao_val
    eval "$_ao_var=\"\$_ao_val\""
}

# vim:ft=sh
