#!/bin/bash
#
# bash specifically: run_step below prefixes each script with the `time`
# keyword, which dash has no equivalent for.
#
# this is different from a .cmd (dosbatch) file
# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# TODO : add a check for total available size

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
config_environment_directory() {
    echo "Checking that environment directory exists"
    if ! [ -d $softwaredir/environment ]; then
        echo "Attempting to access private repo: "
        git clone git@github.com:swinman/environment.git $softwaredir/environment
        if ! [ $? = 0 ]; then
            # https, not the git:// this used to fall back to.  github turned
            # off the unauthenticated git protocol in 2022, so that second
            # attempt could only ever fail as well, which turned a missing ssh
            # key into two failures and no clone.
            echo "Access failed, attempting as public user: "
            git clone https://github.com/swinman/environment.git $softwaredir/environment
        fi
    else
        echo "  fetching most recent changes"
        git --git-dir=$softwaredir/environment/.git \
            --work-tree=$softwaredir/environment/ \
            pull origin
    fi
}

config_chromium() {
    sudo apt-get install chromium-browser -y
    if [ -z $(grep "BROWSER=chromium-browser" ~/.pam_environment | wc -l) ]; then
        echo BROWSER=chromium-browser >> ~/.pam_environment
    fi
}

# Every question the run will ask, put before any of the work starts.  The
# scripts below still prompt for these when run on their own; ask_once and the
# exported $CONFIG_PROMPTS_DONE are what keep them from asking twice here.
collect_answers() {
    echo
    echo "=============== all_config.sh: questions up front ==============="
    echo "Answer these now, then the rest of the run is unattended."
    echo
    ask_once CFG_GIT_USERNAME "Full user name for git (ENTER for no change): "
    ask_once CFG_GIT_EMAIL    "Email address for git (ENTER for no change): "
    # Only asked when there is nothing to find.  config_ssh puts the same
    # question, but ask_once goes quiet once the answers have been taken, so a
    # question left out of this block is answered blank instead of being asked
    # later.  The wait for the key to reach github is not a question and still
    # happens down in config_ssh.
    if ! ssh_key_path >/dev/null; then
        ask_once CFG_SSH_KEYGEN "No ssh key found.  Generate one? [Y/n] "
    fi
    if [ "$OS" = "mac" ]; then
        # Only worth asking when it would be acted on.  sudo is already primed
        # at this point, so -n answers without a password prompt of its own;
        # config_remote_login repeats the check before using the answer.
        if [ "$(sudo -n systemsetup -getremotelogin 2>/dev/null)" \
                != "Remote Login: On" ]; then
            ask_once CFG_REMOTE_LOGIN \
                "Enable Remote Login (incoming ssh)? [y/N] "
        fi
    fi
    # Asked on both now that config_latex.sh has a mac path.  It stays a
    # question rather than riding along with the rest, because the full TeX Live
    # it installs is several GB.
    ask_once ADD_LATEX "Would you like to set up latex? [y/N] "
    if [ "$OS" = "linux" ]; then
        ask_once ADD_CHROMIUM "Add chromium as the default browser? [N/y] "
    fi
    export CFG_GIT_USERNAME CFG_GIT_EMAIL CFG_REMOTE_LOGIN CFG_SSH_KEYGEN
    export CONFIG_PROMPTS_DONE=1
    echo
}

get_build_tools() {
    [ "$OS" = "linux" ] || return 0
    echo "Getting host build tools"
    sudo apt-get install build-essential -y
    sudo apt-get install jq -y
    sudo apt-get install unzip -y
    sudo apt-get install unp -y
}

# A step that fails does not stop the ones after it - they are mostly
# independent, and a run that stopped dead would leave more undone than it
# fixed.  What must not happen is the failure scrolling past under twenty
# minutes of apt output, which is how a run that built neither a venv nor a
# toolchain still looked like it had worked.
FAILED=""
run_step() {
    if time "$SETUPDIR/$1"; then
        return 0
    fi
    echo "  WARNING: $1 failed"
    FAILED="$FAILED $1"
}

report_steps() {
    echo
    echo "==================== all_config.sh: $OS ===================="
    if [ -z "$FAILED" ]; then
        echo "Every step completed."
    else
        echo "FAILED - re-run each on its own once the cause is fixed:"
        for _rs in $FAILED; do
            echo "    $SETUPDIR/$_rs"
        done
    fi
}

# --------------------- SETUP SCRIPT --------------------- #
SETUPDIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
. "$SETUPDIR/config_common.sh"

# sourced, not executed: config_shell.sh's check_os exports $OS, which every
# branch below reads.  It is safe to run first on mac now that its rc editing
# no longer needs GNU sed (see the write-temp-then-replace note in there).
. "$SETUPDIR/config_shell.sh"

ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$SETUPDIR/.." && pwd -P)}

# Both before the dispatch, and in this order: collect_answers asks about
# Remote Login only when it is off, and that check needs a validated sudo to
# answer without prompting for a password itself.
prime_sudo
collect_answers

if [ "$OS" = "mac" ]; then
    # ----------------------------------------------------------------- #
    # mac: bare bones only.
    #
    # Everything below this block is apt-get based and battle tested on
    # ubuntu only, so mac deliberately does NOT fall through to it.  Add
    # one script at a time here as each is audited and ported, so this
    # grows into a full mac setup without ever risking a half-ported run.
    #
    # not applicable: config_udev (linux device rules)
    # not wanted:     config_avr_arm (AVR is out; the ARM half config_mac.sh
    #                 already covers), config_fpga (no macOS iCEcube2 exists -
    #                 VHDL compiles remotely, see TODO.md)
    # ----------------------------------------------------------------- #
    run_step config_mac.sh
    run_step config_git.sh
    run_step config_vim.sh
    run_step config_claude.sh
    run_step config_python.sh
    if [ "$ADD_LATEX" = "y" ]; then
        run_step config_latex.sh
    fi
    report_steps
    echo "Open a new terminal (or 'exec zsh') to pick up ~/.zshrc changes."
    echo "==========================================================="
    exit 0
fi

run_step config_git.sh
config_environment_directory;
get_build_tools;
run_step config_vim.sh
run_step config_python.sh
if [ "$ADD_LATEX" = "y" ]; then
    run_step config_latex.sh
fi
run_step config_avr_arm.sh
run_step config_fpga.sh
run_step config_udev.sh
report_steps
echo "Open a new terminal to pick up ~/.bashrc changes."
echo "==========================================================="
#if [ "$ADD_CHROMIUM" = "y" ]; then
#    config_chromium;
#fi
