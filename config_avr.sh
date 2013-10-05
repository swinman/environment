#!/bin/sh

# this is different from a .cmd (dosbatch) file
# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# TODO : add a check for total available size

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_avr_tools() {
    sudo apt-get install gdb-avr
    # try avr-gdb and avr-run ... doesn't seem like there is much here..
    sudo apt-get install gdb-doc
}


config_avr() {
    if [ $OS = "windows" ]; then
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
    echo "Download avr32 studio for the programmer tools:"
    echo "http://www.atmel.com/tools/AVR32STUDIO2_6.aspx"
    echo
    read -p "Has atmel software framework been downloaded? ([n]/y): " asf_dwn
    read -p "Have avr8 tools been downloaded? ([n]/y): " avr8_dwn
    read -p "Have avr32 tools been downloaded? ([n]/y): " avr32_dwn
    read -p "Have atmel headers been downloaded? ([n]/y): " ahead_wdwn
    read -p "Has avr32 studio been downloaded? ([n]/y): " as4_dwn
    if [ $OS = "linux" -a "${asf_dwn}" = "y" ]; then
        echo "Extracting and moving asf to $softwaredir"
        unzip -d $DFLD $DFLD/asf-standalone* && rm $DFLD/asf-standalone*
        mv $DFLD/asf-* $softwaredir
    fi
    if [ $OS = "linux" -a "${avr8_dwn}" = "y" ]; then
        echo "Extracting and moving avr8-tools to $TOOLSDIR"
        tar -zxvf $DFLD/avr8-gnu-toolchain* && rm $DFLD/avr8-gnu-tool*.tar.gz
        mv avr8-gnu-toolchain* $TOOLSDIR/avr8-tools
        echo PATH\ DEFAULT=$\{PATH}:$TOOLSDIR/avr8-tools/bin \
            >> ~/.pam_environment
    fi
    if [ $OS = "linux" -a "${avr32_dwn}" = "y" ]; then
        echo "Extracting and moving avr32-tools to $TOOLSDIR"
        tar -zxvf $DFLD/avr32-gnu-toolchain* && rm $DFLD/avr32-gnu-tool*.tar.gz
        mv avr32-gnu-toolchain* $TOOLSDIR/avr32-tools
        echo PATH\ DEFAULT=$\{PATH}:$TOOLSDIR/avr32-tools/bin \
            >> ~/.pam_environment
    fi
    if [ $OS = "linux" -a "${ahead_wdwn}" = "y" ]; then
        echo "Extracting and moving avr32-headers to $TOOLSDIR"
        unzip -d $DFLD $DFLD/atmel-headers* && rm $DFLD/atmel-header*.zip
        mv $DFLD/atmel-headers*/avr32 $TOOLSDIR/avr32-tools/avr32/include && \
            rm -r $DFLD/atmel-headers*
    fi
    if [ $OS = "linux" -a "${as4_dwn}" = "y" ]; then
        echo "Extracting and moving avr32-prog tools to $TOOLSDIR"
        unzip -d $DFLD $DFLD/avr32studio-ide* && rm $DFLD/avr32studio-ide*
        mv $DFLD/as4e-ide $TOOLSDIR
        echo PATH\ DEFAULT=$\{PATH}:$TOOLSDIR/as4e-ide/plugins/com.atmel.avr.utilities.linux.x86_64_3.0.0.201009140848/os/linux/x86_64/bin \
            >> ~/.pam_environment
    fi
    read -p "Would you like to get the gtkterm terminal ([n]/y): " done
    if [ $OS = "linux" -a "${done}" = "y" ]; then
        echo "installing 'gtkterm'"
        sudo apt-get install gtkterm
    fi
    if [ $OS = "linux" ]; then
        echo "Adding atmel device usb ids to plugdev rules (logout necessary)"
        sudo cp $softwaredir/environment/99-uCtools.rules /etc/udev/rules.d/
        echo "If user does not appear below, add user to plugdev group"
        less /etc/group | grep plugdev
    else
        echo "Unzip tools folders, move tools to $TOOLSDIR"
        echo "from $TOOLSDIR add to path: avr32-tools/bin, avr8-tools/bin, av"
        echo "      avr32-tools/bin"
        echo "      avr8-tools/bin"
        echo "      avr32-prog"
        echo "Unzip asf folder, move asf-version to $softwaredir"
        echo "Acquire the appropriate atmel cdc and dfu drivers"
    fi
    echo "You may need to logout for changes to function"
}

config_dfu() {
    if [ $OS = "linux" ]; then
        echo "getting dfu-programmer set up"
        get_git_proj dfu-programmer;
        echo "gathering required packages"
        sudo apt-get install autoconf libusb-1.0-0-dev
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

run_full_script() {
    # on linux, get git & xclip
    # get dfuprogrammer project and install dfu-programmer
    config_dfu;

    # add plugdev rules for accessing atmel devices
    config_avr;
}

# --------------------- SETUP SCRIPT --------------------- #
########## RUN WHATEVER YOU WANT DOWN HERE ############

run_full_script;
#

#config_avr;
#update_default_programs;
#config_avr;
#config_dfu;
#get_avr32prog_tools;

#add_bash_alias;
#get_python_packages;
#config_python;

#additional_software;
#get_vim_addons;
