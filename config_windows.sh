#!/bin/bash

#VIMDIR=$HOME/vimfiles
VIMDIR=$HOME/.vim
VIMRC=$HOME/.vimrc


config_vim() {
    text="source ~/software/environment/_vimrc"
    target=$VIMRC
    mkdir -p ~/.tmp
    echo "Checking if $target has \"$text\""
    # change \ to . for grep to avoid matching the slash
    text2=$(echo "$text" | sed 's|\\|.|g')
    has=$(grep "$text2" $target | wc -l)
    if [ $has = 0 ]; then
        echo "adding \"$text\" to $target"
        echo "$text" >> $target
    fi
    mkdir -p $VIMDIR/colors
    CDIR="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )/colorvim/colors"
    for fn in $(ls $CDIR/*.vim); do
        FB=$(basename $fn)
        if [ -f $VIMDIR/colors/$FB ]; then
            echo "color file $FB already exists"
        else
            ln -sv $CDIR/$FB -t $VIMDIR/colors/
        fi
    done
}

get_vim_pathogen() {
    echo "Getting vim add-on packages"
    # get vim packages, including pathogen

    if ! [ -d $VIMDIR/autoload ]; then
        echo "making $VIMDIR/autoload"
        mkdir -p $VIMDIR/autoload
    fi
    rm -f $VIMDIR/autoload/pathogen.vim.new
    curl -LSso $VIMDIR/autoload/pathogen.vim.new \
        https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
    if [ -e $VIMDIR/autoload/pathogen.vim.new ]; then
        echo "Updating pathogen.vim to newest version"
        if [ -e $VIMDIR/autoload/pathogen.vim ]; then
            mv $VIMDIR/autoload/pathogen.vim $VIMDIR/autoload/pathogen.vim.bak
        fi
        mv $VIMDIR/autoload/pathogen.vim.new $VIMDIR/autoload/pathogen.vim
    fi

    #undo directory for persistent undo history
    if ! [ -d $VIMDIR/undo ]; then
        mkdir -p $VIMDIR/undo
    fi
}

get_vim_addons() {
    # set windows driver vim filetype to dosini
    VBUND=$VIMDIR/bundle
    GHURL=https://github.com
    VIMFT=$VIMDIR/filetype.vim
    if ! [ -d $VBUND ]; then
        echo "making $VBUND"
        mkdir -p $VBUND
    fi
    echo "if exists('did_load_filetypes')" > $VIMFT
    echo "    finish" >> $VIMFT
    echo "endif" >> $VIMFT
    echo "augroup filetypedetect" >> $VIMFT
    echo "autocmd BufNewFile,BufRead *.inf setf dosini" >> $VIMFT
    echo "augroup END" >> $VIMFT

    get_git_repo $GHURL/jiangmiao/auto-pairs.git $VBUND/auto-pairs
    get_git_repo $GHURL/scrooloose/syntastic.git $VBUND/syntastic
    get_git_repo $GHURL/tpope/vim-sensible.git $VBUND/vim-sensible
    get_git_repo $GHURL/tpope/vim-fugitive.git $VBUND/vim-fugitive
    get_git_repo $GHURL/tpope/vim-surround.git $VBUND/vim-surround
    get_git_repo $GHURL/gregjurman/vim-nc.git $VBUND/ngc
    #get_git_repo $GHURL/davidhalter/jedi-vim.git $VBUND/jedi-vim --recursive

    if [ -n "YES" ]; then
        get_git_repo hg::https://heptapod.host/cgtk/taghighlight $VBUND/taghighlight
    else
        echo "Attempting to access private repo: "
        get_git_repo git@github.com:swinman/taghighlight.git $VBUND/taghighlight
        if ! [ $? = 0 ]; then
            echo "Access failed, attempting as public user: "
            #get_git_repo $GHURL/swinman/taghighlight.git $VBUND/taghighlight
            get_git_repo git://github.com/swinman/taghighlight.git $VBUND/taghighlight
        fi
    fi

    if [ -e $VIMDIR/bundle/neocomplcache ]; then
        mkdir -p $VIMDIR/unused
        mv $VIMDIR/bundle/neocomplcache $VIMDIR/unused
    fi
}

get_git_repo() {
    local repourl=$1
    local folder=$2
    local flag=$3
    if ! [ -d $folder ]; then
        echo "Clone $repourl to $folder with flag '$flag'"
        git clone $3 $repourl $folder
    else
        echo "Synch $folder"
        git --git-dir=$folder/.git --work-tree=$folder/ pull
    fi
}

run_full_script() {
    get_vim_pathogen;
    # set .vimrc in home/username to point to vimrc in $softwaredir/environment/_vimrc
    config_vim;
    # get vim add-ons (this requires git)
    get_vim_addons;
}

# --------------------- RUN SCRIPT --------------------- #
echo "==================== config_vim.sh  ===================="
run_full_script;
echo "=============== END: config_vim.sh  ===================="
