#!/bin/sh

get_vim_packages() {
    echo "Getting required vim packages"
    if [ "${OS}" = "linux" ]; then
        sudo apt-get install vim-gnome -y
        sudo apt-get install vim-doc -y
        sudo apt-get install ttf-dejavu -y
        sudo apt-get install exuberant-ctags -y
        sudo apt-get install cscope -y
        sudo apt-get install curl -y
    fi
}

config_vim() {
    echo $OS
    if [ $OS = windows ]; then
        text="source $softwaredir\\environment\\_vimrc"
        target=~/_vimrc
    else
        text="source $softwaredir/environment/_vimrc"
        target=~/.vimrc
    fi
    echo "Checking if $target has \"$text\""
    has=$(grep "$text" $target | wc -l)
    if [ $has = 0 ]; then
        echo "adding \"$text\" to $target"
        echo "$text" >> $target
    fi
}

get_vim_addons() {
    echo "Getting vim add-on packages"
    # get vim packages, including pathogen
    if [ $OS = windows ]; then
        VIMDIR=~/vimfiles
    else
        VIMDIR=~/.vim
    fi
    VBUND=$VIMDIR/bundle
    GHURL=git://github.com

    if ! [ -d $VIMDIR/autoload ]; then
        mkdir -p $VIMDIR/autoload
    fi
    if ! [ -d $VBUND ]; then
        mkdir -p $VBUND
    fi
    if ! [ -e $VIMDIR/autoload/pathogen.vim ]; then
        curl -Sso $VIMDIR/autoload/pathogen.vim \
            https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
    fi
    get_git_repo $GHURL/jiangmiao/auto-pairs.git $VBUND/auto-pairs
    get_git_repo $GHURL/scrooloose/nerdtree.git $VBUND/nerdtree
    get_git_repo $GHURL/scrooloose/syntastic.git $VBUND/syntastic
    get_git_repo $GHURL/klen/rope-vim.git $VBUND/rope-vim
    get_git_repo $GHURL/tpope/vim-sensible.git $VBUND/vim-sensible
    get_git_repo $GHURL/tpope/vim-fugitive.git $VBUND/vim-fugitive
    get_git_repo $GHURL/SirVer/ultisnips.git $VBUND/ultisnips

    echo "Attempting to access private repo: "
    get_git_repo git@github.com:swinman/taghighlight.git $VBUND/taghighlight
    if ! [ $? = 0 ]; then
        echo "Access failed, attempting as public user: "
        get_git_repo git://github.com/swinman/taghighlight.git $VBUND/taghighlight
    fi
    echo "Attempting to access private repo: "
    get_git_repo git@github.com:swinman/colorvim.git $VBUND/colorvim
    if ! [ $? = 0 ]; then
        echo "Access failed, attempting as public user: "
        get_git_repo git://github.com/swinman/colorvim.git $VBUND/colorvim
    fi
    if [ -e $VIMDIR/bundle/neocomplcache ]; then
        mkdir -p $VIMDIR/unused
        mv $VIMDIR/bundle/neocomplcache $VIMDIR/unused
    fi
}

get_git_repo() {
    local repourl=$1
    local folder=$2
    if ! [ -d $folder ]; then
        echo "Clone $repourl to $folder"
        git clone $repourl $folder
    else
        echo "Synch $folder"
        git --git-dir=$folder/.git --work-tree=$folder/ pull
    fi
}

run_full_script() {
    get_vim_packages;
    # set .vimrc in home/username to point to vimrc in $softwaredir/environment/_vimrc
    config_vim;
    # get vim add-ons (this requires git)
    get_vim_addons;
}

# --------------------- RUN SCRIPT --------------------- #
echo "==================== config_vim.sh  ===================="
run_full_script;
echo "=============== END: config_vim.sh  ===================="
