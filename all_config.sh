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
        git clone git@github.com:swinman/environment.git $softwaredir/environment
    else
        echo "  fetching most recent changes"
        git --git-dir=$softwaredir/environment/.git \
            --work-tree=$softwaredir/environment/ \
            fetch origin
    fi
}

config_chromium() {
    read -p "Add chromium as the default browser? ([n]/y)" no
    if [ "$no" = "y" ]; then
        sudo apt-get install chromium-browser -y
        if [ -z $(grep "BROWSER=chromium-browser" ~/.pam_environment | wc -l) ]; then
            echo BROWSER=chromium-browser >> ~/.pam_environment
        fi
    fi
}

######### also for opening text files or html file defaults
update_default_programs() {
    sudo sed -i -E "s/^(text\/html=)[^.]*/\1chromium/" /etc/gnome/defaults.list
    sudo sed -i -E "s/^(text\/xml=)[^.]*/\1chromium/" /etc/gnome/defaults.list
    sudo sed -i -E "s/^(text\/plain=)[^.]*/\1gvim/" /etc/gnome/defaults.list
    sudo sed -i -E "s/^(text\/x-java=)[^.]*/\1gvim/" /etc/gnome/defaults.list
    sudo sed -i -E "s/^(text\/x-python=)[^.]*/\1gvim/" /etc/gnome/defaults.list
    sudo sed -i -E "s/^(text\/x-sql=)[^.]*/\1gvim/" /etc/gnome/defaults.list
}

# --------------------- SETUP SCRIPT --------------------- #
source ./config_bash.sh
./config_git.sh
config_environment_directory;
./config_vim.sh
./config_python.sh
./config_latex.sh
./config_arm.sh
#./config_avr.sh
sudo apt-get install sc -y
update_default_programs;
config_chromium;
