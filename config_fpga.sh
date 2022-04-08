#!/bin/sh

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
# download the quartus web edition tool

# add to path ....
# PATH DEFAULT=\${PATH}:$toolsdir/lscc/iCEcube2.2014.04/

# the following aliases are part of _bash_aliases
#alias vsim='$toolsdir/altera/*/modelsim_ase/linux/vsim'
#alias quartus='$toolsdir/altera/*/quartus/bin/quartus'

# the synpbase code needs to be patched becuase bash is not the
# default /bin/sh terminal -- see icecube_2017.01_use_bash.patch

# Download Altera Quartus Lite software as a single file - you want to install
# only the cyclone portions -- don't want the other larger chips

install_packages() {
    if [ "$OS" = "linux" ]; then
        # tejainece related
            sudo dpkg --add-architecture i386
            sudo apt-get update

            sudo apt-get install gcc-multilib -y
            sudo apt-get install g++-multilib -y
            sudo apt-get install lib32z1 -y
            sudo apt-get install lib32stdc++6 -y
            sudo apt-get install lib32gcc1 -y
            sudo apt-get install expat:i386 -y
            sudo apt-get install fontconfig:i386 -y
            sudo apt-get install libfreetype6:i386 -y
            sudo apt-get install libexpat1:i386 -y
            sudo apt-get install libc6:i386 -y
            sudo apt-get install libgtk-3-0:i386 -y
            sudo apt-get install libcanberra0:i386 -y
            sudo apt-get install libice6:i386 -y
            sudo apt-get install libsm6:i386 -y
            sudo apt-get install libncurses5:i386 -y
            sudo apt-get install zlib1g:i386 -y
            sudo apt-get install libx11-6:i386 -y
            sudo apt-get install libxau6:i386 -y
            sudo apt-get install libxdmcp6:i386 -y
            sudo apt-get install libxext6:i386 -y
            sudo apt-get install libxft2:i386 -y
            sudo apt-get install libxrender1:i386 -y
            sudo apt-get install libxt6:i386 -y
            sudo apt-get install libxtst6:i386 -y


        if [ $(lsb_release -a | grep Codename | grep focal | wc -l) -eq 1 ]; then
            sudo add-apt-repository ppa:linuxuprising/libpng12
            sudo apt update
            sudo apt install libpng12-0

            sudo apt-get install libbz2-1.0:i386 -y
            sudo apt-get install lib32ncurses6 -y
        else
            sudo apt-get install libpng12-0:i386 -y
            sudo apt-get install lib32bz2-1.0 -y
            sudo apt-get install lib32ncurses5 -y
        fi



        # iCECube2 related
            sudo apt-get install lib32z1 -y
            sudo apt-get install libxext6:i386 -y
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
            sudo apt-get install libelf1:i386
        # lattice programmer related
            sudo apt-get install rpm2cpio -y
            sudo apt-get install cpio -y
            sudo apt-get install libelf1:i386 -y
        # quartus related
            sudo apt-get install build-essential
    fi
}

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
                unp $DFLD/iCEcube2_*.tgz
                ./iCEcube2setup*
            fi
            if [ -f programmer_*-linux.rpm ]; then
                unp programmer_*-linux.rpm
                mv usr/local/programmer $toolsdir/lscc/
            fi
        fi
    fi
}

tejainece_git_script() {
    ALTERA_PATH=$toolsdir/altera/15.0/
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

check_eth_addr() {
    echo "In order to have a license for lattice you need an eth0 device"
    echo "run ifconfig -a | grep \"^[^ ]\""
    echo "swap out enp0s31f6 for eth0"
    echo 'SUBSYSTEM=="net", ACTION="add", ATTR{address}=="xx:xx:xx:xx:xx:xx", NAME="eth0"'
}
# --------------------- SETUP SCRIPT --------------------- #
########## RUN WHATEVER YOU WANT DOWN HERE ############

echo "==================== config_fpga.sh ===================="
install_packages;
#config_icecube2;
#tejainece_git_script;

echo "=============== END: config_fpga.sh ===================="
