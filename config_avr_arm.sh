#!/bin/sh

# to run this dd below line (minus #) into "r, then use @r
#! chmod 755 %; %
# to run a line individually, do the above, but yy instead of dd
# 0i! <Esc>"ryy@ruu

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
get_packages() {
    echo "Getting embedded development packages"
    sudo apt-get install openocd -y
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



# The Arm GNU Toolchain, from Arm's gitlab package registry.
#
# That registry is where Arm publishes now, and where homebrew's
# gcc-arm-embedded cask pulls from, so mac and linux can run the same build.
# The older developer.arm.com/-/media/Files/downloads/gnu/ paths still serve
# releases up to 15.2 but 404 on anything current.
#
# The version is set here rather than tracking whatever is newest, because
# firmware builds record `arm-none-eabi-gcc -dumpversion` in their build
# metadata.  A toolchain that moved on its own would change build records with
# no commit saying so.  Bump it deliberately, and bump the mac with it - the
# brew cask autobumps, so the two drift apart otherwise.
ARM_TOOLCHAIN_VER=${ARM_TOOLCHAIN_VER:-15.3.rel1}
ARM_TOOLCHAIN_URL="https://gitlab.arm.com/api/v4/projects/tooling%2Fgnu-toolchains-for-arm/packages/generic/gnu-toolchain"

get_gcc_arm() {
    [ "$OS" = "linux" ] || return 0

    _ga_dir="$toolsdir/arm-none-eabi"
    if [ -x "$_ga_dir/bin/arm-none-eabi-gcc" ]; then
        echo "arm-none-eabi present: gcc $("$_ga_dir/bin/arm-none-eabi-gcc" -dumpversion)"
        return 0
    fi

    case "$(uname -m)" in
        x86_64) _ga_arch=x86_64 ;;
        aarch64) _ga_arch=aarch64 ;;
        *)
            echo "  WARNING: Arm publishes no toolchain for $(uname -m)" >&2
            return 1
            ;;
    esac

    command -v curl >/dev/null 2>&1 || sudo apt-get install curl -y
    command -v xz >/dev/null 2>&1 || sudo apt-get install xz-utils -y

    _ga_name="arm-gnu-toolchain-$ARM_TOOLCHAIN_VER-$_ga_arch-arm-none-eabi"
    _ga_tmp=$(mktemp -d)
    echo "Fetching $_ga_name"
    if ! curl -fSL --progress-bar -o "$_ga_tmp/tc.tar.xz" \
            "$ARM_TOOLCHAIN_URL/$ARM_TOOLCHAIN_VER/$_ga_name.tar.xz"; then
        echo "  WARNING: download failed, no arm-none-eabi toolchain" >&2
        rm -rf "$_ga_tmp"
        return 1
    fi

    # --strip-components=1 drops the tarball's versioned top level, so the
    # tools land at $toolsdir/arm-none-eabi/bin - the one path _aliases puts
    # on PATH, whatever version is installed under it.
    echo "Extracting to $_ga_dir"
    mkdir -p "$_ga_dir"
    if ! tar -xJf "$_ga_tmp/tc.tar.xz" -C "$_ga_dir" --strip-components=1; then
        echo "  WARNING: extract failed" >&2
        rm -rf "$_ga_tmp" "$_ga_dir"
        return 1
    fi
    rm -rf "$_ga_tmp"
    echo "  installed gcc $("$_ga_dir/bin/arm-none-eabi-gcc" -dumpversion)"
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

rc=0
get_gcc_arm || rc=1

#config_avr;

#install_tools;
#get_avr_tools
#config_avr;

# get dfuprogrammer project and install dfu-programmer
#config_dfu;
echo "================= END: config_avr_arm.sh ==================="
exit $rc
