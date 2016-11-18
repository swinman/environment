#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
set_os() {
    OS=$linux
    echo "OS is set to $OS"
    export OS=$OS
}

set_common_dir() {
    SOFTWAREDIR=$HOME/software
    TOOLSDIR=$HOME/tools
}

init_software_dir() {
    echo "Checking that $SOFTWAREDIR exists"
    if ! [ -d $SOFTWAREDIR ]; then
        echo "Adding directory $SOFTWAREDIR"
        mkdir -p $SOFTWAREDIR
    fi
    echo "Checking if $TOOLSDIR exists"
    if ! [ -d $TOOLSDIR ]; then
        echo "Adding directory $TOOLSDIR"
        mkdir -p $TOOLSDIR
        echo "Adding $TOOLSDIR to .profile PATH"
        echo "" >> ~/.profile
        echo PATH=$\{PATH}:$TOOLSDIR >> ~/.profile
    fi
}

add_bash_alias() {
    BRC=~/.bashrc
    if ! [ -e $BRC ]; then
        touch $BRC
    fi

    #sed -i 's/#\(force_color_prompt=yes\)/\1/' $BRC

    aliases='$softwaredir/environment/_bash_aliases'
    startline="##### START DO NOT EDIT BETWEEN THESE BRACKETS #####"
    infoline="# Below lines were added by environment/config script"
    endline="##### END DO NOT EDIT BETWEEN THESE BRACKETS #####"

    sno=$(grep "$startline" -n $BRC | sed "s/:.*//")
    eno=$(grep "$endline" -n $BRC | sed "s/:.*//")

    # if both start and end numbers are found, remove lines in between
    if [ -n "$sno" ] && [ -n "$eno" ]; then
	if [ $sno -ge 0 ] && [ $eno -gt $sno ]; then
            echo "Removing lines $sno to $eno from $BRC"
	    sed -i -e "$sno,$eno d" $BRC
	fi
    fi


    # check if last line is blank, if not add a blank line
    llb=$(grep -n -v "^." $BRC | grep $(wc -l $BRC | sed 's/^ *//' | sed 's/ .*//') | wc -l)
    if [ $llb -eq 0 ]; then
        echo "" >> $BRC
    fi

    echo $startline >> $BRC
    echo $infoline >> $BRC
    echo "Adding \$OS variable"
    echo "export OS=$OS" >> $BRC
    echo "Adding \$softwaredir and \$toolsdir variables"
    echo "export softwaredir=\"$SOFTWAREDIR\"" >> $BRC
    echo "export toolsdir=\"$TOOLSDIR\"" >> $BRC
    echo "export PYTHONPATH=\"\$PYTHONPATH:$SOFTWAREDIR\"" >> $BRC
    echo "export PYTHONPATH=\"\$PYTHONPATH:$SOFTWAREDIR/pyusb\"" >> $BRC
    echo "" >> $BRC
    echo "Sourcing aliases from $aliases"
    echo "if [ -f $aliases ]; then" >> $BRC
    echo "    . $aliases" >> $BRC
    echo "fi" >> $BRC
    echo "" >> $BRC
    echo $endline >> $BRC
}

ensure_req_globals() {
    if [ -z "$softwaredir" ]; then
        echo "exporting softwaredir"
        export softwaredir=$SOFTWAREDIR
    fi
    if [ -z "$toolsdir" ]; then
        echo "exporting toolsdir"
        export toolsdir=$TOOLSDIR
    fi
}

setup_python() {
    sudo apt-get install libblas-dev liblapack-dev libatlas-base-dev gfortran -y
    sudo apt-get install python python3 python3-pip -y
    sudo pip3 install gpiozero numpy raspi flask wtforms
    sudo pip3 install jupyter
}

get_vim_packages() {
    echo "Getting required vim packages"
    sudo apt-get install vim -y
    sudo apt-get install exuberant-ctags -y
    sudo apt-get install cscope -y
    sudo apt-get install curl -y
}

config_vim() {
    text="source $softwaredir/environment/_vimrc"
    target=~/.vimrc
    echo "Checking if $target has \"$text\""
    # change \ to . for grep to avoid matching the slash
    text2=$(echo "$text" | sed 's|\\|.|g')
    has=$(grep "$text2" $target | wc -l)
    if [ $has = 0 ]; then
        echo "adding \"$text\" to $target"
        echo "$text" >> $target
    fi
}

get_vim_addons() {
    echo "Getting vim add-on packages"
    # get vim packages, including pathogen
    VIMDIR=~/.vim
    VBUND=$VIMDIR/bundle
    GHURL=git://github.com

    if ! [ -d $VIMDIR/autoload ]; then
        mkdir -p $VIMDIR/autoload
    fi
    if ! [ -d $VBUND ]; then
        mkdir -p $VBUND
    fi
    if ! [ -e $VIMDIR/autoload/pathogen.vim ]; then
        curl -LSso $VIMDIR/autoload/pathogen.vim \
            https://raw.github.com/tpope/vim-pathogen/master/autoload/pathogen.vim
    fi

    # set windows driver vim filetype to dosini
    VIMFT=$VIMDIR/filetype.vim
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
    local flag=$3
    if ! [ -d $folder ]; then
        echo "Clone $repourl to $folder with flag '$flag'"
        git clone $3 $repourl $folder
    else
        echo "Synch $folder"
        git --git-dir=$folder/.git --work-tree=$folder/ pull
    fi
}

# --------------------- RUN SCRIPT --------------------- #
windows=windows
mac=mac
linux=linux

echo "=================== config_raspi.sh ===================="
set_os;
set_common_dir;
init_software_dir;
add_bash_alias;
ensure_req_globals;

sudo apt-get update
sudo apt-get install git -y
get_vim_packages;
config_vim;
get_vim_addons;
setup_python;
echo "================ END: config_raspi.sh ================="
