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
            echo "Access failed, attempting as public user: "
            git clone git://github.com/swinman/environment.git $softwaredir/environment
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
    export CFG_GIT_USERNAME CFG_GIT_EMAIL CFG_REMOTE_LOGIN
    export CONFIG_PROMPTS_DONE=1
    echo
}

######### also for opening text files or html file defaults
update_default_programs() {
    if [ "$OS" = "linux" ]; then
        sudo sed -i -E "s/^(text\/html=)[^.]*/\1chromium/" /etc/gnome/defaults.list
        sudo sed -i -E "s/^(text\/xml=)[^.]*/\1chromium/" /etc/gnome/defaults.list
        sudo sed -i -E "s/^(text\/plain=)[^.]*/\1gvim/" /etc/gnome/defaults.list
        sudo sed -i -E "s/^(text\/x-java=)[^.]*/\1gvim/" /etc/gnome/defaults.list
        sudo sed -i -E "s/^(text\/x-python=)[^.]*/\1gvim/" /etc/gnome/defaults.list
        sudo sed -i -E "s/^(text\/x-sql=)[^.]*/\1gvim/" /etc/gnome/defaults.list
    fi
}

# --------------------- SETUP SCRIPT --------------------- #
# sourced, not executed: config_shell.sh's check_os exports $OS, which every
# branch below reads.  It is safe to run first on mac now that its rc editing
# no longer needs GNU sed (see the write-temp-then-replace note in there).
. ./config_shell.sh

ENVDIR=${ENVDIR:-$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)}
. "$ENVDIR/config_common.sh"

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
    # not applicable: config_udev (linux device rules), update_default_programs
    # not wanted:     config_avr_arm (AVR is out; the ARM half config_mac.sh
    #                 already covers), config_fpga (no macOS iCEcube2 exists -
    #                 VHDL compiles remotely, see TODO.md)
    # ----------------------------------------------------------------- #
    time ./config_mac.sh
    time ./config_git.sh
    time ./config_vim.sh
    time ./config_claude.sh
    time ./config_python.sh
    if [ "$ADD_LATEX" = "y" ]; then
        time ./config_latex.sh
    fi
    echo
    echo "==================== all_config.sh: mac ===================="
    echo "Ran: config_shell.sh, config_mac.sh, config_git.sh, config_vim.sh,"
    echo "     config_claude.sh, config_python.sh"
    if [ "$ADD_LATEX" = "y" ]; then
        echo "     config_latex.sh"
    fi
    echo "Open a new terminal (or 'exec zsh') to pick up ~/.zshrc changes."
    echo "==========================================================="
    exit 0
fi

time ./config_git.sh
config_environment_directory;
if [ "$OS" = "linux" ]; then
    #sudo apt-get install sc -y
    sudo apt-get install unp -y
fi
time ./config_vim.sh
time ./config_python.sh
if [ "$ADD_LATEX" = "y" ]; then
    time ./config_latex.sh
fi
time ./config_avr_arm.sh
time ./config_fpga.sh
time ./config_udev.sh
update_default_programs;
#if [ "$ADD_CHROMIUM" = "y" ]; then
#    config_chromium;
#fi
