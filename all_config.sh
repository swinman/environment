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

if [ "$OS" = "mac" ]; then
    # ----------------------------------------------------------------- #
    # mac: bare bones only.
    #
    # Everything below this block is apt-get based and battle tested on
    # ubuntu only, so mac deliberately does NOT fall through to it.  Add
    # one script at a time here as each is audited and ported, so this
    # grows into a full mac setup without ever risking a half-ported run.
    #
    # not yet ported: config_git, config_latex, config_avr_arm, config_fpga
    # not applicable: config_udev (linux device rules), update_default_programs
    # ----------------------------------------------------------------- #
    time ./config_mac.sh
    time ./config_vim.sh
    time ./config_claude.sh
    time ./config_python.sh
    echo
    echo "==================== all_config.sh: mac ===================="
    echo "Ran: config_shell.sh, config_mac.sh, config_vim.sh, config_claude.sh,"
    echo "     config_python.sh"
    echo "Open a new terminal (or 'exec zsh') to pick up ~/.zshrc changes."
    echo "==========================================================="
    exit 0
fi

read -p "Would you like to set up latex? [y/N]" add_latex
if [ "$OS" = "linux" ]; then
    read -p "Add chromium as the default browser? [N/y]" add_chromium
fi
time ./config_git.sh
config_environment_directory;
if [ "$OS" = "linux" ]; then
    #sudo apt-get install sc -y
    sudo apt-get install unp -y
fi
time ./config_vim.sh
time ./config_python.sh
if [ "$add_latex" = "y" ]; then
    time ./config_latex.sh
fi
time ./config_avr_arm.sh
time ./config_fpga.sh
time ./config_udev.sh
update_default_programs;
#if [ "$add_chromium" = "y" ]; then
#    config_chromium;
#fi
