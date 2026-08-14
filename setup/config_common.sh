# config_common.sh - helpers shared by the config_*.sh scripts.
#
# Sourced, not executed:
#
#     SETUPDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
#     ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$SETUPDIR/.." && pwd -P)}
#     . "$SETUPDIR/config_common.sh"
#     start_log "$@"
#
# $ENVDIR is the repo root, one above these scripts, and is what every path
# passed to link_config is relative to.  It is normally exported by
# config_shell.sh; scripts fall back to deriving it so each stays runnable on
# its own before config_shell.sh has been run for the first time on a new
# machine.

# --------------------- run log --------------------- #

# start_log "$@"
#
# Re-exec the calling script with its output going to setup/log.log as well as
# the terminal.  A run driven from a plain terminal - which is where the sudo
# ones have to happen - is then recoverable in full afterwards.
#
# Called by the scripts that are entry points.  A script run as a step of
# all_config.sh inherits both the pipe and $CONFIG_LOG, so there is only ever
# one tee, and one log, per run.
#
# The status has to travel out of the pipe through a file: these are /bin/sh
# scripts and there is no PIPESTATUS.  Reporting tee's status instead would
# make every step of all_config.sh look like it had passed.
start_log() {
    [ -n "${CONFIG_LOG:-}" ] && return 0

    _sl_log="$SETUPDIR/log.log"
    # A log left root-owned by a `sudo ./setup/...` run is the likely reason.
    # Not worth failing the setup over.
    if ! ( : >> "$_sl_log" ) 2>/dev/null; then
        echo "  WARNING: cannot write $_sl_log, running without a log" >&2
        return 0
    fi

    CONFIG_LOG="$_sl_log"
    export CONFIG_LOG
    _sl_cmd="$0"
    [ $# -gt 0 ] && _sl_cmd="$0 $*"
    _sl_rc=$(mktemp)

    printf '\n===== %s  START  %s =====\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$_sl_cmd" >> "$_sl_log"
    { "$0" "$@" 2>&1; echo $? > "$_sl_rc"; } | tee -a "$_sl_log"
    _sl_status=$(cat "$_sl_rc")
    rm -f "$_sl_rc"
    printf '===== %s  END    %s (exit %s) =====\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$_sl_cmd" "$_sl_status" |
        tee -a "$_sl_log"

    exit "$_sl_status"
}

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

# --------------------- ssh --------------------- #

# ssh_key_path
#
# Echo the private key github would be offered, or nothing when there is none.
# ed25519 is tried first so a machine carrying both is not judged by an rsa key
# left behind by an older run of these scripts.
ssh_key_path() {
    for _sk in "$HOME/.ssh/id_ed25519" "$HOME/.ssh/id_rsa"; do
        if [ -f "$_sk" ]; then
            echo "$_sk"
            return 0
        fi
    done
    return 1
}

# github_ssh_ok
#
# github answers -T with exit 1 whether or not it recognised the key, so the
# greeting text is the only signal there is.  accept-new keeps a first-ever
# connection from stopping on the host key question without turning the check
# off, and the timeout keeps a machine with no route from parking here.
github_ssh_ok() {
    ssh -T -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 \
        git@github.com 2>&1 | grep -q "successfully authenticated"
}

# copy_to_clipboard <file>
#
# Fails when there is no clipboard to copy to, which is the normal case over a
# bare ssh session.  Callers print the file as well rather than relying on this.
copy_to_clipboard() {
    if [ "$OS" = "mac" ]; then
        pbcopy < "$1"
    elif command -v xclip >/dev/null 2>&1; then
        # xclip stays resident to serve the selection, and it inherits stdout.
        # Left attached, it holds the pipe open for as long as it owns the
        # clipboard, so anything reading this script's output waits on it
        # rather than on the script.
        xclip -sel clip < "$1" >/dev/null 2>&1
    else
        return 1
    fi
}

# config_ssh
#
# Get github answering over ssh, and do not return until it does.  all_config.sh
# clones a private repo immediately after config_git.sh; that clone is the first
# thing a new machine asks a key to do, and it fails quietly, so the wait for the
# key to be posted belongs here where it can still be acted on.
#
# Nothing happens on a machine github already accepts, so re-running is silent.
config_ssh() {
    echo
    echo "Checking ssh access to github"
    if github_ssh_ok; then
        echo "  already accepted: $(ssh_key_path)"
        return 0
    fi

    _cs_key=$(ssh_key_path)
    if [ -z "$_cs_key" ]; then
        ask_once CFG_SSH_KEYGEN "No ssh key found.  Generate one? [Y/n] "
        case "$CFG_SSH_KEYGEN" in
            n|N)
                echo "  skipped - clones over ssh will fail"
                return 0
                ;;
        esac
        _cs_key="$HOME/.ssh/id_ed25519"
        _cs_label=$(git config --global user.email 2>/dev/null)
        [ -n "$_cs_label" ] || _cs_label="$USER"
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$_cs_label on $(hostname)" -f "$_cs_key" ||
            return 1
    else
        echo "  $_cs_key exists, but github did not accept it"
    fi

    # The public half is derivable from the private one, so a missing .pub is
    # recoverable rather than a reason to stop.  An earlier version of this
    # copied a .pub it had never created, and silently copied nothing.
    [ -f "$_cs_key.pub" ] || ssh-keygen -y -f "$_cs_key" > "$_cs_key.pub"

    if [ "$OS" = "mac" ]; then
        ssh-add --apple-use-keychain "$_cs_key"
    elif [ -n "$SSH_AUTH_SOCK" ]; then
        ssh-add "$_cs_key"
    else
        echo "  no agent running, ssh-add skipped"
    fi

    if copy_to_clipboard "$_cs_key.pub"; then
        echo "  public key copied to the clipboard"
    fi
    echo
    cat "$_cs_key.pub"
    echo
    echo "Add it at https://github.com/settings/ssh/new"
    while ! github_ssh_ok; do
        printf "ENTER once the key is posted to github (s to skip): "
        read _cs_ans
        case "$_cs_ans" in
            s|S)
                echo "  skipped - clones over ssh will fail"
                return 0
                ;;
        esac
    done
    echo "  github accepts $_cs_key"
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
