#!/bin/sh
#
# config_shell.sh - was config_bash.sh.  Renamed because it configures the
# login shell's rc file, whichever shell that is: bash on the linux boxes,
# zsh on mac (the default there since Catalina).  The aliases it sources are
# kept shell-agnostic rather than forked per shell, so there is nothing
# bash-specific left to justify the old name.

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
    if [ $OS = FALSE_windows ]; then
        SOFTWAREDIR=$USERPROFILE\\Documents\\software
        TOOLSDIR=$USERPROFILE\\tools
    else
        SOFTWAREDIR=$HOME/software
        TOOLSDIR=$HOME/tools
    fi
    ENVIRONMENTDIR=$SOFTWAREDIR/environment
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
# note - pam_environment is no longer supported, moved this to fpga_config
#	if ! [ "$OS" = "windows" ]; then
#		echo "Adding $TOOLSDIR to .pam_environment PATH"
#		echo PATH\ DEFAULT=$\{PATH}:$TOOLSDIR >> ~/.pam_environment
#	fi
    fi
}

add_shell_rc() {
    # the rc file the login shell actually reads
    if [ "$OS" = "mac" ]; then
        BRC=~/.zshrc
    else
        BRC=~/.bashrc
    fi

    if ! [ -e $BRC ]; then
        touch $BRC
    fi

    # Ubuntu's stock .bashrc ships this line commented out; uncomment it.
    # zsh has no such setting and mac colors come from CLICOLOR, so linux
    # only - which also keeps this GNU-sed call off the mac path.
    if [ "$OS" = "linux" ]; then
        sed -i 's/#\(force_color_prompt=yes\)/\1/' $BRC
    fi

    # one shell-agnostic aliases file for both shells and both OSes -
    # _bash_aliases was renamed to _aliases, there is no per-shell copy.
    aliases='$ENVDIR/_aliases'
    startline="##### START DO NOT EDIT BETWEEN THESE BRACKETS #####"
    infoline="# Below lines were added by environment/config script"
    endline="##### END DO NOT EDIT BETWEEN THESE BRACKETS #####"

    sno=$(grep "$startline" -n $BRC | sed "s/:.*//")
    eno=$(grep "$endline" -n $BRC | sed "s/:.*//")

    # if both start and end numbers are found, remove lines in between
    if [ -n "$sno" ] && [ -n "$eno" ]; then
	if [ $sno -ge 0 ] && [ $eno -gt $sno ]; then
            echo "Removing lines $sno to $eno from $BRC"
	    # not sed -i: BSD sed (mac) reads -i's argument as a backup
	    # suffix, so `sed -i -e ...` dies with "unescaped newline inside
	    # substitute pattern" there.  write-temp-then-replace is portable,
	    # and `cat tmp > $BRC` rewrites in place so perms survive.
	    sed -e "$sno,$eno d" $BRC > $BRC.tmp \
		&& cat $BRC.tmp > $BRC \
		&& rm -f $BRC.tmp
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
    echo "Adding \$ENVDIR variable"
    echo "export ENVDIR=\"$ENVIRONMENTDIR\"" >> $BRC
    # $softwaredir exists mainly because it used to be put on PYTHONPATH so
    # imports resolved out of ~/software.  Per-project venvs make that both
    # unnecessary and undesirable, so new code should use $ENVDIR instead.
    # Still exported because older scripts in here read it.
    echo "Adding \$softwaredir and \$toolsdir variables (legacy - prefer \$ENVDIR)"
    echo "export softwaredir=\"$SOFTWAREDIR\"" >> $BRC
    echo "export toolsdir=\"$TOOLSDIR\"" >> $BRC
    echo "" >> $BRC
    echo "Sourcing aliases from $aliases"
    echo "if [ -f $aliases ]; then" >> $BRC
    echo "    . $aliases" >> $BRC
    echo "fi" >> $BRC
    echo "" >> $BRC
    # Activate the default venv, so `pip install` lands in something
    # disposable rather than on a system python.  Guarded twice: an already
    # active venv is never replaced, so a project venv chosen deliberately
    # wins, and a missing venv is not an error, so this rc block still works
    # before config_venv.sh has been run.  Path must match its VENVDIR.
    echo "Adding default venv activation"
    echo "if [ -z \"\$VIRTUAL_ENV\" ] && [ -f \$HOME/.venvs/dev/bin/activate ]; then" >> $BRC
    echo "    . \$HOME/.venvs/dev/bin/activate" >> $BRC
    echo "fi" >> $BRC
    echo "" >> $BRC
    # the old mac branch sourced ~/git-completion.bash here.  That was for
    # mac-on-bash; zsh gets git completion from brew's zsh-completions via
    # the FPATH/compinit lines config_mac.sh checks for, so it is dropped.
    if [ "$OS" = "windows" ]; then
        echo "adding cd to softwaredir for windows"
        echo 'cd $HOME' >> $BRC
        echo "" >> $BRC
    fi
    echo $endline >> $BRC
}

ensure_req_globals() {
    if [ -z "$ENVDIR" ]; then
        echo "exporting ENVDIR"
        export ENVDIR=$ENVIRONMENTDIR
    fi
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

echo "==================== config_shell.sh ===================="
check_os;
set_common_dir;
init_software_dir;
add_shell_rc;
ensure_req_globals;
echo "================= END: config_shell.sh =================="
