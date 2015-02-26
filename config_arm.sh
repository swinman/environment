#!/bin/sh

#! chmod 755 %; %

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
config_rules() {
    if [ $OS = linux ]; then
        echo "Config arm device plugdev rules"
        sudo cp $softwaredir/environment/99-uCtools.rules /etc/udev/rules.d/
        echo "Ensuring correct permissions are set"
        for GROUP in plugdev dialout; do
            if [ -z $(grep $GROUP /etc/group)  ]; then
                echo "Adding the group $GROUP"
                sudo groupadd $GROUP
            fi
            if [ -z $(grep $GROUP /etc/group | grep $USER) ]; then
                echo "Adding $USER to $GROUP"
                sudo usermod -a -G $GROUP $USER
            fi
        done
    fi
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

get_packages() {
    if [ "$OS" = "linux" ]; then
        sudo apt-get install libusb-0.1-4:i386 -y
        # sudo apt-get install lpc21isp -y
        sudo apt-get install gtkterm -y
        sudo apt-get install unp -y
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

get_openocd() {
    if [ "$OS" = "linux" ]; then
        # sudo apt-get install openocd -y
        sudo apt-get install libtool -y
        sudo apt-get install autoconf -y
        sudo apt-get install automake -y
        sudo apt-get install texinfo -y
        sudo apt-get install libusb-1.0-0-dev -y
        if [ -d $toolsdir/openocd ]; then
            (cd $toolsdir/openocd && git pull)
        else
            (cd $toolsdir && git clone git://git.code.sf.net/p/openocd/code openocd)
            (cd $toolsdir/openocd && ./bootstrap)
            (cd $toolsdir/openocd && ./configure --enable-stlink --enable-jlink)
        fi
        (cd $toolsdir/openocd && make)
        (cd $toolsdir/openocd && sudo make install)
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
echo "==================== config_arm.sh ====================="
install_tools;
config_rules;
get_packages;
get_openocd;
echo "================= END: config_arm.sh ==================="
