#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_packages() {
    sudo apt-get install libusb-0.1-4:i386 -y
    # sudo apt-get install lpc21isp -y
    sudo apt-get install unp -y
    sudo apt-get install libtool -y
    sudo apt-get install autoconf -y
    sudo apt-get install automake -y
    sudo apt-get install texinfo -y
    sudo apt-get install libhidapi-dev -y
    sudo apt-get install libusb-1.0-0-dev -y
    sudo apt-get install libc6 -y
    sudo apt-get install libncurses5 -y
    sudo apt-get install gtkterm -y
}

install_tools() {
    DFLD=~/Downloads
    echo
    echo "Download j-link software to $DFLD"
    echo "http://www.segger.com/jlink-software.html"
    echo
    echo "Download saleae software to $DFLD"
    echo "http://www.saleae.com/downloads"
    echo
    read -p "[ ENTER ] when software has been downloaded." jlink_dwn
    if [ "$OS" = "linux" ]; then
        if [ -f $DFLD/JLink_Linux*.tgz ]; then
            FOLDERNAME=$(ls $DFLD | grep JLink_Linux | sed 's/\(.*\)\.tgz/\1/')
            echo "Extracting and moving $FOLDERNAME to $toolsdir"
            (cd $DFLD && unp JLink_Linux* && rm $FOLDERNAME.tgz)
            (cd $DFLD/$FOLDERNAME && sudo cp libjlinkarm.so.* /usr/lib)
            (cd $DFLD/$FOLDERNAME && sudo cp 45-jlink.rules /etc/udev/rules.d/)
            mv $DFLD/$FOLDERNAME $toolsdir
            sudo ldconfig
            if [ "$(grep $FOLDERNAME ~/.pam_environment)" = "" ]; then
                echo PATH\ DEFAULT=$\{PATH}:$toolsdir/$FOLDERNAME \
                    >> ~/.pam_environment
            fi
            echo "It will now be necessary to restart the system"
        fi
        if [ -f $DFLD/Logic*.zip ]; then
            FOLDERNAME=$(ls $DFLD | grep Logic | sed 's/\(.*\)\.zip/\1/')
            echo "Extracting and moving $FOLDERNAME to $toolsdir"
            (cd $DFLD && unp Logic* && rm "$FOLDERNAME.zip")
    #        (cd $DFLD/$FOLDERNAME && sudo cp libjlinkarm.so.* /usr/lib)
    #        (cd $DFLD/$FOLDERNAME && sudo cp 45-jlink.rules /etc/udev/rules.d/)
            NEWFOLDERNAME=$(echo $FOLDERNAME | sed "s/ /_/g" | sed "s/[()]//g")
            mv $DFLD/"$FOLDERNAME" $toolsdir/$NEWFOLDERNAME
            if [ "$(grep $NEWFOLDERNAME ~/.pam_environment)" = "" ]; then
                echo PATH\ DEFAULT=$\{PATH}:$toolsdir/$NEWFOLDERNAME \
                    >> ~/.pam_environment
            fi
            sudo cp $toolsdir/$NEWFOLDERNAME/Drivers/99-SaleaeLogic.rules \
                /etc/udev/rules.d/
            echo "It will now be necessary to restart the system"
        fi
    fi
}

get_avr_tools() {
    sudo apt-get install gdb-avr -y
    # try avr-gdb and avr-run ... doesn't seem like there is much here..
    sudo apt-get install gdb-doc -y
}

get_gcc_arm() {
    if [ "$OS" = "linux" ]; then
        if [ ! -d $toolsdir/arm-none-eabi ]; then
            if [ ! -f $toolsdir/arm-gnu-toolchain-*-linux.any.x86_64.tar.gz ]; then
                wget -P $toolsdir "https://www.microchip.com/mymicrochip/filehandler.aspx?ddocname=en603996"
            fi
            if [ -f $toolsdir/arm-gnu-toolchain-*-linux.any.x86_64.tar.gz ]; then
                echo "Extracting and moving arm binaries to $toolsdir"
                unp $toolsdir/arm-gnu-toolchain-*.x86_64.tar.gz
                mv arm-none-eabi $toolsdir
            fi
        else
            echo "arm-none-eabi tools already present"
        fi
        if [ -d $toolsdir/arm-none-eabi ]; then
            FOLDERNAME=arm-none-eabi/bin
            if [ "$(grep $FOLDERNAME ~/.pam_environment)" = "" ]; then
                echo "adding $toolsdir/$FOLDERNAME to path"
                echo PATH\ DEFAULT=$\{PATH}:$toolsdir/$FOLDERNAME \
                    >> ~/.pam_environment
            fi
        fi
    fi
}

get_gcc_arm_OLD() {
    if [ "$OS" = "linux" ]; then
        if [ "$(ls /etc/apt/sources.list.d/ | grep "gcc-arm-embedded")" = "" ]; then
            if [ "$(lsb_release -r | sed "s/.*\s\+\(.*\)/\1/")" = "14.04" ]; then
                sudo apt-get remove binutils-arm-none-eabi gcc-arm-none-eabi -y
            fi
            sudo add-apt-repository ppa:terry.guo/gcc-arm-embedded
            sudo apt-get update
        fi
        GCCARMNONE=gcc-arm-none-eabi
        if [ "$(lsb_release -r | sed "s/.*\s\+\(.*\)/\1/")" = "14.04" ]; then
            GCCARMNONE=gcc-arm-none-eabi=4.9.3.2014q4-0trusty12
        fi
        echo ">>>>>>>>>>> using $GCCARMNONE >>>>>>>>>>>"
        sudo apt-get install $GCCARMNONE -y
    else
        echo
        echo "Download and install arm-none-eabi-gcc"
        echo "https://launchpad.net/gcc-arm-embedded/+download"
        echo
        echo "Download openocd, add bin to path, rename as openocd.exe"
        echo "http://www.freddiechopin.info/en/download/category/4-openocd"
        echo "You need 7z to extract: http://www.7-zip.org/"
        echo
        echo "Install the stm32 vlink driver"
        echo "http://www.st.com/web/en/catalog/tools/PF258167"
    fi
}

config_avr() {
    if [ "$OS" = "windows" ]; then
        DFLD=~/Downloads
        echo "Download atmel software framework to $DFLD"
        echo "http://www.atmel.com/tools/AVRSOFTWAREFRAMEWORK.aspx"
        TOOLURL="http://www.atmel.com/tools/ATMELAVRTOOLCHAINFORWINDOWS.aspx"
        echo "Download 'avr8', 'avr32' and 'headers' to $DFLD:"
        echo $TOOLURL
        read -p "[ ENTER ] when software has been downloaded." jlink_dwn
        echo "Unzip tools folders, move tools to $toolsdir"
        echo "from $toolsdir add to path: avr32-tools/bin, avr8-tools/bin, av"
        echo "      avr32-tools/bin"
        echo "      avr8-tools/bin"
        echo "      avr32-prog"
        echo "Unzip asf folder, move asf-version to $softwaredir"
        echo "Acquire the appropriate atmel cdc and dfu drivers"
    fi
    if [ "$OS" = "linux" ]; then
        if [ ! -d $softwaredir/libs/xdk-asf-3.35.1 ]; then
            wget -P /tmp/ "lucidsci.com/atmel/asf-standalone-archive-3.35.1.54.zip"
            if [ -f /tmp/asf-standalone*.zip ]; then
                echo "Extracting and moving asf to $softwaredir"
                unzip -d /tmp/ /tmp/asf-standalone*
                mkdir -p $softwaredir/libs
                mv /tmp/xdk-asf-* $softwaredir/libs
            fi
        else
            echo "ASF version 3.35 already present"
        fi

        if [ ! -d $toolsdir/avr8-tools ]; then
            wget -P /tmp/ "lucidsci.com/atmel/avr8-gnu-toolchain-3.5.4.1709-linux.any.x86_64.tar.gz"
            if [ -f /tmp/avr8-gnu-toolchain-3.5.4.1709-linux.any.x86_64.tar.gz ]; then
                echo "Extracting and moving avr8-tools to $toolsdir"
                tar -zxvf /tmp/avr8-gnu-toolchain-3.5.4.1709-linux.any.x86_64.tar.gz
                mv avr8-gnu-toolchain* $toolsdir/avr8-tools
                echo PATH\ DEFAULT=$\{PATH}:$toolsdir/avr8-tools/bin \
                    >> ~/.pam_environment
            fi
        else
            echo "avr8 tools already present"
        fi

        if [ ! -d $toolsdir/avr32-tools ]; then
            wget -P /tmp/ "lucidsci.com/atmel/avr32-gnu-toolchain-3.4.3.820-linux.any.x86_64.tar.gz"
            if [ -f /tmp/avr32-gnu-toolchain-3.4.3.820-linux.any.x86_64.tar.gz ]; then
                echo "Extracting and moving avr32-tools to $toolsdir"
                tar -zxvf /tmp/avr32-gnu-toolchain-3.4.3.820-linux.any.x86_64.tar.gz
                mv avr32-gnu-toolchain* $toolsdir/avr32-tools
                echo PATH\ DEFAULT=$\{PATH}:$toolsdir/avr32-tools/bin \
                    >> ~/.pam_environment
            fi
        else
            echo "avr32 tools already present"
        fi

        if [ ! -d $toolsdir/avr32-tools/avr32/avr32/include/avr32 ]; then
            wget -P /tmp/ "lucidsci.com/atmel/avr32-headers-6.2.0.742.zip"
            if [ -f /tmp/avr32-headers-6.2.0.742.zip ]; then
                echo "Extracting and moving avr32-headers to $toolsdir"
                unzip -d /tmp/ /tmp/avr32-headers-6.2.0.742.zip
                mv /tmp/avr32 $toolsdir/avr32-tools/avr32/include/avr32
            else
                echo "Failed to extract avr32-headers"
            fi
        else
            echo "avr32 headers already present"
        fi
    fi
}

get_openocd() {
    if [ "$OS" = "linux" ]; then
        # sudo apt-get install openocd -y
        if [ -d $softwaredir/libs/openocd ]; then
            (cd $toolsdir/libs/openocd && git pull)
        else
            (cd $softwaredir && git clone git://git.code.sf.net/p/openocd/code openocd)
            (cd $softwaredir/libs/openocd && ./bootstrap)
            (cd $softwaredir/libs/openocd && ./configure --enable-stlink --enable-jlink --enable-cmsis-dap)
        fi
        (cd $softwaredir/libs/openocd && make)
        (cd $softwaredir/libs/openocd && sudo make install)
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
echo "==================== config_avr_arm.sh ====================="
if [ "$OS" = "linux" ]; then
    get_packages;
fi

get_gcc_arm;

#config_avr;

#install_tools;
#get_avr_tools
#config_avr;

# get dfuprogrammer project and install dfu-programmer
#config_dfu;
#get_openocd;
echo "================= END: config_avr_arm.sh ==================="
