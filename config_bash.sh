#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
check_os() {
    if [ "$OS" = "$windows" ]; then
        OS=$windows
    elif [ "$OS" = "windows" ]; then
        OS=$windows
    elif [ "$OS" = "windowsnt" ]; then
        OS=$windows
    elif [ "$OS" = "Windows_NT" ]; then
        OS=$windows

    elif [ "$OS" = "$mac" ]; then
        OS=$mac
    elif [ "$OS" = "mac" ]; then
        OS=$mac
    elif [ "$OS" = "darwin" ]; then
        OS=$mac
    elif [ "$OS" = "Darwin" ]; then
        OS=$mac

    elif [ "$OS" = "$linux" ]; then
        OS=$linux
    elif [ "$OS" = "linux" ]; then
        OS=$linux
    elif [ "$OS" = "Linux" ]; then
        OS=$linux
    else
        OS=`uname`
    fi

    if [ "$OS" = "Linux" ]; then
        OS=$linux
    elif [ "$OS" = "Darwin" ]; then
        OS=$mac
    fi

    echo "OS is set to $OS"
    export OS=$OS
}

set_common_dir() {
    if [ $OS = "windows" ]; then
        SOFTWAREDIR=$USERPROFILE\\Documents\\software
        TOOLSDIR=$USERPROFILE\\tools
    else
        SOFTWAREDIR=$HOME/software
        TOOLSDIR=$HOME/tools
    fi
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
	if ! [ "$OS" = "windows" ]; then
		echo "Adding $TOOLSDIR to .pam_environment PATH"
		echo PATH\ DEFAULT=$\{PATH}:$TOOLSDIR >> ~/.pam_environment
	fi
    fi
}

add_bash_alias() {
    if [ "$OS" = "mac" ]; then
        BRC=~/.bash_profile
    else
        BRC=~/.bashrc
    fi

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
    echo "" >> $BRC
    echo "Sourcing aliases from $aliases"
    echo "if [ -f $aliases ]; then" >> $BRC
    echo "    . $aliases" >> $BRC
    echo "fi" >> $BRC
    echo "" >> $BRC
    if [ "$OS" = "mac" ]; then
        echo "adding git autocomplete for mac"
        echo "if [ -f $HOME/git-completion.bash ]; then" >> $BRC
        echo "    source $HOME/git-completion.bash" >> $BRC
        echo "fi" >> $BRC
    fi
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


# --------------------- RUN THE SCRIPT ------------------------------- #
windows=windows
mac=mac
linux=linux

echo "==================== config_bash.sh ===================="
sed -i 's/#\(force_color_prompt=yes\)/\1/' ~/.bashrc
check_os;
set_common_dir;
init_software_dir;
add_bash_alias;
ensure_req_globals;
echo "========================================================"
