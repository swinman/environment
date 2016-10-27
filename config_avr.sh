#!/bin/sh

# this is different from a .cmd (dosbatch) file
# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# TODO : add a check for total available size

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_avr_tools() {
    sudo apt-get install gdb-avr -y
    # try avr-gdb and avr-run ... doesn't seem like there is much here..
    sudo apt-get install gdb-doc -y
}

config_avr() {
    if [ "$OS" = "windows" ]; then
        TOOLURL="http://www.atmel.com/tools/ATMELAVRTOOLCHAINFORWINDOWS.aspx"
    else
        TOOLURL="http://www.atmel.com/tools/ATMELAVRTOOLCHAINFORLINUX.aspx"
    fi
    DFLD=~/Downloads
    echo
    echo "Download atmel software framework to $DFLD"
    echo "http://www.atmel.com/tools/AVRSOFTWAREFRAMEWORK.aspx"
    echo
    echo "Download 'avr8', 'avr32' and 'headers' to $DFLD:"
    echo $TOOLURL
    echo
    read -p "[ ENTER ] when software has been downloaded." jlink_dwn
    if [ "$OS" = "linux" ]; then
        if [ -f $DFLD/asf-standalone*.zip ]; then
            echo "Extracting and moving asf to $softwaredir"
            unzip -d $DFLD $DFLD/asf-standalone* && rm $DFLD/asf-standalone*
            mkdir -p $softwaredir/libs
            mv $DFLD/xdk-asf-* $softwaredir/libs
        fi
        if [ -f $DFLD/avr8-gnu-tool*.tar.gz ]; then
            echo "Extracting and moving avr8-tools to $toolsdir"
            tar -zxvf $DFLD/avr8-gnu-toolchain* && rm $DFLD/avr8-gnu-tool*.tar.gz
            mv avr8-gnu-toolchain* $toolsdir/avr8-tools
            echo PATH\ DEFAULT=$\{PATH}:$toolsdir/avr8-tools/bin \
                >> ~/.pam_environment
        fi
        if [ -f $DFLD/avr32-gnu-tool*.tar.gz ]; then
            echo "Extracting and moving avr32-tools to $toolsdir"
            tar -zxvf $DFLD/avr32-gnu-toolchain* && rm $DFLD/avr32-gnu-tool*.tar.gz
            mv avr32-gnu-toolchain* $toolsdir/avr32-tools
            echo PATH\ DEFAULT=$\{PATH}:$toolsdir/avr32-tools/bin \
                >> ~/.pam_environment
        fi
        if [ -f $DFLD/atmel-header*.zip ]; then
            echo "Extracting and moving avr32-headers to $toolsdir"
            unzip -d $DFLD $DFLD/atmel-headers* && rm $DFLD/atmel-header*.zip
            mv $DFLD/atmel-headers*/avr32 $toolsdir/avr32-tools/avr32/include && \
                rm -r $DFLD/atmel-headers*
        elif [ -f $DFLD/avr32-headers*.zip ]; then
            echo "Extracting and moving avr32-headers to $toolsdir"
            unzip -d $DFLD $DFLD/avr32-headers* && rm $DFLD/avr32-headers*.zip
            mv $DFLD/avr32 $toolsdir/avr32-tools/avr32/include
        fi
        read -p "Would you like to get the gtkterm terminal ([n]/y): " done
        if [ "${done}" = "y" ]; then
            echo "installing 'gtkterm'"
            sudo apt-get install gtkterm -y
        fi
    else
        echo "Unzip tools folders, move tools to $toolsdir"
        echo "from $toolsdir add to path: avr32-tools/bin, avr8-tools/bin, av"
        echo "      avr32-tools/bin"
        echo "      avr8-tools/bin"
        echo "      avr32-prog"
        echo "Unzip asf folder, move asf-version to $softwaredir"
        echo "Acquire the appropriate atmel cdc and dfu drivers"
    fi
}

config_plugdev() {
    if [ "$OS" = "linux" ]; then
        echo "Adding device usb ids to plugdev rules"
        sudo cp $softwaredir/environment/99-uCtools.rules /etc/udev/rules.d/
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        echo "If user does not appear below, add user to plugdev group"
        less /etc/group | grep plugdev
    fi
}

config_dfu() {
    if [ "$OS" = linux ]; then
        echo "getting dfu-programmer set up"
        get_git_proj dfu-programmer;
        echo "gathering required packages"
        sudo apt-get install autoconf libusb-1.0-0-dev -y
        echo "configure dfu-programmer"
        $softwaredir/dfu-programmer/bootstrap.sh
        $softwaredir/dfu-programmer/configure
        echo "make and install"
        make -C $softwaredir/dfu-programmer/src
        sudo make -C $softwaredir/dfu-programmer/src install
        (cd $softwaredir/dfu-programmer/src && ctags-exuberant -R)
        (cd $softwaredir/dfu-programmer/src && cscope -R -b)
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
########## RUN WHATEVER YOU WANT DOWN HERE ############

# get dfuprogrammer project and install dfu-programmer
#config_dfu;

# add plugdev rules for accessing atmel devices
config_avr;
config_plugdev;
