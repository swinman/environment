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
        if [ $(lsb_release -a | grep Codename | grep focal | wc -l) -eq 1 ]; then
            sudo dpkg --add-architecture i386
            sudo apt-get update

            # Step 1: Update your system
            sudo apt update
            sudo apt upgrade

            # Step 2: Install 32-bit dependencies
            sudo apt install gcc-10-base:i386 -y

            # packages only in our script
            if [ 0 ]; then
                sudo apt install expat:i386 -y
                sudo apt install fontconfig:i386 -y
                sudo apt install g++-multilib -y
                sudo apt install gcc-multilib -y
                sudo apt install lib32gcc1 -y
                sudo apt install lib32z1 -y
                sudo apt install libcanberra0:i386 -y
                sudo apt install libgtk-3-0:i386 -y
                sudo apt install libice6:i386 -y
                sudo apt install libncurses5:i386 -y
                sudo apt install libx11-6:i386 -y
                sudo apt install libxau6:i386 -y
                sudo apt install libxdmcp6:i386 -y
                sudo apt install libxft2:i386 -y
                sudo apt install libxt6:i386 -y
                sudo apt install libxtst6:i386 -y
            fi

            # packages in both scripts
            if [ 1 ]; then
                sudo apt install lib32stdc++6 -y
                sudo apt install libc6:i386 -y
                sudo apt install libexpat1:i386 -y
                sudo apt install libfreetype6:i386 -y
                sudo apt install libsm6:i386 -y
                sudo apt install libxext6:i386 -y
                sudo apt install libxrender1:i386 -y
                sudo apt install zlib1g:i386 -y
            fi

            # packages in their script
            if [ 0 ]; then
                sudo apt install lib32stdc++6 -y
                sudo apt install libfontconfig1:i386 -y
                sudo apt install libgcc-s1:i386 -y
                sudo apt install libglib2.0-0 -y
                sudo apt install libglib2.0-0:i386 -y
                sudo apt install libidn2-0:i386 -y
                sudo apt install libunistring2:i386 -y
                sudo apt install libxcursor1:i386 -y
                sudo apt install libxfixes3:i386 -y
                sudo apt install libxi6:i386 -y
                sudo apt install libxinerama1:i386 -y
                sudo apt install libxrandr2:i386 -y
            fi

            # THIS IS IMPORTANT
            if [ 0 ]; then # Step 3: Install 32-bit libpng12 with modified paths
                wget vhdlwhiz.com/wp-content/uploads/2020/05/\
                    libpng12-0_1.2.54-1ubuntu1b_i386.deb

                sudo dpkg -i libpng12-0_1.2.54-1ubuntu1b_i386.deb && rm libpng12-0_1.2.54-1ubuntu1b_i386.deb
            fi

            # not necessary, we change to eth0 elsewhere
            if [ 0 ]; then # Step 4a: Make a backup of the GRUB config
                sudo cp /etc/default/grub /etc/default/grub_original

                # Update 2020-08-10:
                #   See Peter Uran's comment on this blog post for an
                #   alternative method of changing the network interface name
                #   vhdlwhiz.com/lattice-icecube2-ubuntu-20-04-icestick#comment-73154


                # Step 4b: Change the default network name from "ens33" to "eth0"
                OLD_STRING='GRUB_CMDLINE_LINUX=\"find_'
                NEW_STRING='GRUB_CMDLINE_LINUX=\"net.ifnames=0 biosdevname=0 find_'
                sudo sed -i "s/$OLD_STRING/$NEW_STRING/g" /etc/default/grub

                # Step 4c: Check the changes (compare to my diff below this listing)
                diff /etc/default/grub /etc/default/grub_original

                # Step 4d: Update the GRUB config and reboot
                sudo update-grub
                sudo reboot

                # Step 4e: Check that the network name is now "eth0"
                ip link show
            fi

            # install from whl -- but use the latest
            if [ 0 ]; then   # Step 5: Unpack and install Lattice iCEcube2
                cd
                tar zxf ./iCEcube2setup_Sep_12_2017_1708.tgz
                chmod +x iCEcube2setup_Sep_12_2017_1708
                ./iCEcube2setup_Sep_12_2017_1708
            fi

            # IMPORTANT after install - but needs adjusting for date etc
            if [ 0 ]; then # Step 6a: Replace #!/bin/sh shebang with #!/bin/bash recursively
                find ~/lscc/iCEcube2.2017.08/synpbase/bin/ \
                    -type f -exec sed -i '1s/#\!\/bin\/sh/#\!\/bin\/bash/g' {} \;

                # Step 6b: Replace some occurrences of /bin/sh with /bin/bash
                find ~/lscc/iCEcube2.2017.08/synpbase/lib/ \
                    -type f -exec sed -i 's/\/bin\/sh /\/bin\/bash /g' {} \;
                find ~/lscc/iCEcube2.2017.08/synpbase/lib/ \
                    -type f -exec sed -i "s/'\/bin\/sh'/'\/bin\/bash'/g" {} \;
            fi

            if [ 0 ]; then # Step 7: Start iCEcube2
                ~/lscc/iCEcube2.2017.08/iCEcube2
            fi
        fi

        if [ 0 ]; then      # OLD tejainece method
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
                # DON'T DO THIS -- it prevents vhdlwhiz install
                sudo apt install libpng12-0 -y      # need i386 instead

                sudo apt-get install libbz2-1.0:i386 -y
                sudo apt-get install lib32ncurses6 -y

            else
                sudo apt-get install libpng12-0:i386 -y
                sudo apt-get install lib32bz2-1.0 -y
                sudo apt-get install lib32ncurses5 -y

            fi
        fi

        if [ 1 ]; then # iCECube2 related
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
        fi

        if [ 1 ]; then # lattice programmer related
            sudo apt-get install rpm2cpio -y
            sudo apt-get install cpio -y
            sudo apt-get install libelf1:i386 -y
        fi

        if [ 1 ]; then # quartus related
            sudo apt-get install build-essential
        fi
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
