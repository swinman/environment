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
    echo "From http://www.latticesemi.com/icecube2"
    echo "   download programmer, icecube2 and checksums to $DFLD"
    echo unp\ all,\ then\ run
    read -p "[ ENTER ] when software has been downloaded." jlink_dwn
    if [ "$OS" = "linux" ]; then
        if [ -f $DFLD/linuxinstallersmd* ]; then
            unp $DFLD/linuxinstallersmd*.tgz
            mkdir $toolsdir/lscc
            if [ -f $DFLD/iCEcube2_*.tgz ]; then
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
                unp $DFLD/iCEcube2_*.tgz
                ./iCEcube2setup*
            fi
            if [ -f programmer_*-linux.rpm ]; then
                sudo apt-get install rpm2cpio -y
                sudo apt-get install cpio -y
                #sudo apt-get install libelf1:i386
                unp programmer_*-linux.rpm
                mv usr/local/programmer $toolsdir/lscc/
            fi
            # for quartus
            sudo apt-get install libxft2:i386 -y
        fi
    fi
}

tejainece_git_script() {
    ALTERA_PATH=$toolsdir/altera/14.0/

    sudo dpkg --add-architecture i386
    sudo apt-get update
    sudo apt-get install -y gcc-multilib g++-multilib lib32z1 lib32stdc++6 \
    lib32gcc1 expat:i386 fontconfig:i386 libfreetype6:i386 libexpat1:i386 \
    libc6:i386 libgtk-3-0:i386 libcanberra0:i386 libpng12-0:i386 libice6:i386 \
    libsm6:i386 libncurses5:i386 zlib1g:i386 libx11-6:i386 libxau6:i386 \
    libxdmcp6:i386 libxext6:i386 libxft2:i386 libxrender1:i386 libxt6:i386 \
    libxtst6:i386
    cd /tmp
    wget http://download.savannah.gnu.org/releases/freetype/freetype-2.4.12.tar.bz2
    tar -xjvf freetype-2.4.12.tar.bz2
    cd freetype-2.4.12
    ./configure --build=i686-pc-linux-gnu \
        "CFLAGS=-m32" "CXXFLAGS=-m32" "LDFLAGS=-m32"
    make -j8

    mkdir ${ALTERA_PATH}modelsim_ase/lib32
    sudo cp objs/.libs/libfreetype.so* ${ALTERA_PATH}modelsim_ase/lib32

    #this file is usually read-only, make it writeable
    chmod 755 ${ALTERA_PATH}modelsim_ase/vco
    echo -e "Add the following line \n\texport
    LD_LIBRARY_PATH=\${dir}/lib32\nafter this line\n\tdir=\`dirname \$arg0\`\nin the file ${ALTERA_PATH}modelsim_ase/vco"
    echo "or dont... it may not be necessary if you use source fconfig"
}

# --------------------- SETUP SCRIPT --------------------- #
########## RUN WHATEVER YOU WANT DOWN HERE ############

echo "==================== config_fpga.sh ===================="
config_icecube2;
#tejainece_git_script;

echo "=============== END: config_fpga.sh ===================="
