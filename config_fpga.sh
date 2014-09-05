#!/bin/sh

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
# download the quartus web edition tool

# add to path ....
# PATH DEFAULT=\${PATH}:$toolsdir/lscc/iCEcube2.2014.04/

# the following aliases are part of _bash_aliases
#alias vsim='$toolsdir/altera/*/modelsim_ase/linux/vsim'
#alias quartus='$toolsdir/altera/*/quartus/bin/quartus'

config_icecube2() {
    DFLD=~/Downloads
    echo
    echo "Download icecube2 from http://www.latticesemi.com/icecube2"
    echo "Download 32 bit programmer, icecube2 and checksums to $DFLD"
    echo unp\ all,\ then\ run
    read -p "[ ENTER ] when software has been downloaded." jlink_dwn
    if [ "$OS" = "linux" ]; then
        if [ -f $DFLD/LinuxInstallersMD532.tgz ]; then
            unp $DFLD/LinuxInstallersMD532.tgz
            mkdir $toolsdir/lscc
            if [ -f $DFLD/icecube2_*.tgz ]; then
                sudo apt-get install lib32z1 lib32ncurses5 lib32bz2-1.0 -y
                sudo apt-get install libxext6:i386 -y
                sudo apt-get install libpng12-0:i386 -y
                sudo apt-get install libsm6:i386 -y
                sudo apt-get install libxi6:i386 -y
                sudo apt-get install libxrender1:i386 -y
                sudo apt-get install libxrandr2:i386 -y
                sudo apt-get install libxfixes3:i386 -y
                sudo apt-get install libxcursor1:i386 -y
                sudo apt-get install libxinerama1:i386 -y
                sudo apt-get install libfreetype6:i386 -y
                sudo apt-get install libfontconfig1:i386 -y
                sudo apt-get install libglib2.0-0:i386 -y
                sudo apt-get install libstdc++6:i386 -y
                unp icecube2*.tgz
                ./iCEcube2setup*
            fi
            if [ -f programmer_*-linux.rpm ]; then
                sudo apt-get install rpm2cpio -y
                sudo apt-get install cpio -y
                #sudo apt-get install libelf1:i386
                unp programmer_*-linux.rpm
                mv usr/local/programmer $toolsdir/lscc/
            fi
        fi
    fi
}


# --------------------- SETUP SCRIPT --------------------- #
########## RUN WHATEVER YOU WANT DOWN HERE ############

echo "==================== config_fpga.sh ===================="
config_icecube2;

echo "=============== END: config_fpga.sh ===================="
