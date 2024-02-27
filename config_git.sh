#!/bin/bash

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_git_packages() {
    echo "Getting required git packages"
    if [ "${OS}" = "linux" ]; then
        sudo apt-get install git -y
        sudo apt-get install xclip -y
        sudo apt-get install mercurial -y
        mkdir -p ~/.local/bin
        wget https://raw.github.com/felipec/git-remote-hg/master/git-remote-hg -O ~/.local/bin/git-remote-hg
        chmod ug+x ~/.local/bin/git-remote-hg
    elif [ $OS = windows ]; then
        echo "Download git and install using 'simple context menu' with bash"
        echo "Download from http://git-scm.com/download/win"
        echo "Install with the following options:"
        echo "run git from the windows command prompt -> add git to path"
        echo "checkout windows style, commit unix style"
    elif [ $OS = mac ]; then
        (curl https://github.com/git/git/raw/master/contrib/completion/git-completion.bash -OL && mv git-completion.bash ~/)
    fi
}

config_git() {
    echo
    gitver=$(git --version | sed "s/^.* \([^.]*\)\.\([^.]*\)\..*/\1\2/")
    echo "git version $gitver, configuring:"
    echo "   color ui to true"
    git config --global color.ui true
    if [ $gitver -ge "19" ]; then
        echo "   push default to simple"
        git config --global push.default simple
    fi
    echo "   linking core excludes file"
    if [ -z "$softwaredir" ]; then
        >&2 echo "softwaredir not set!"
        exit -1
    fi
    git config --global core.excludesfile "$softwaredir/environment/_gitignore"
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
        read -p "Enter when ssh key is posted to github?" answer
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
echo "==================== config_git.sh  ===================="
get_git_packages;
config_git;
echo "================ END: config_git.sh ===================="
