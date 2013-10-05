#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_git_packages() {
    echo "Getting required git packages"
    if [ "${OS}" = "linux" ]; then
        sudo apt-get install git
        sudo apt-get install xclip
    elif [ $OS = windows ]; then
        echo "Download git and install using 'simple context menu' with bash"
        echo "Download from http://git-scm.com/download/win"
        echo "Install with the following options:"
        echo "simple context menu -> use bash instead of cheetah"
        echo "run git from the windows command prompt -> add git to path"
        echo "checkout windows style, commit unix style"
    elif [ $OS = mac ]; then
        (curl https://github.com/git/git/raw/master/contrib/completion/git-completion.bash -OL && mv git-completion.bash ~/)
    fi
}

config_git() {
    echo "\nConfiguring git"
    read -p "Full user name (default is no change): " username
    if [ -n "$username" ]; then
        echo "Setting git user.name to $username"
        git config --global user.name "$username"
    fi
    read -p "Email address (default is no change): " emailaddr
    if [ -n "$emailaddr" ]; then
        echo "Setting git user.email to $emailaddr"
        git config --global user.email "$emailaddr"
    fi
    git config --global color.ui true
    git config --global push.default simple
    git config --global core.excludesfile "$softwaredir/environment/_gitignore"

    read -p "Generate a new ssh key? ([n]/y) " generate
    if [ "$generate" = "y" ]; then
        defkeylabel="$emailaddr on `hostname`"
        read -p "Key Label (defauls \"$defkeylabel\"): " keylabel
        if [ -z "$keylabel" ]; then
            keylabel="$defkeylabel"
        fi
        echo "adding lable as \"$keylabel\""
        ssh-keygen -t rsa -C "$keylabel"

        if [ $OS = linux ]; then
            ssh-add
            xclip -sel clip < ~/.ssh/id_rsa.pub
        elif [ $OS = windows ]; then
            clip < ~/.ssh/id_rsa.pub
        elif [ $OS = mac ]; then
            pbcopy < ~/.ssh/id_rsa.pub
        fi
        read -p "Enter when ssh key is posted to github & bitbucket?" answer
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
echo "==================== config_git.sh  ===================="
get_git_packages;
config_git;
echo "========================================================"
