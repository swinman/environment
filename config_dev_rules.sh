#!/bin/sh

# get the path of directory containing this file
SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

config_rules() {
    echo "Config device plugdev rules"
    echo "Adding device usb ids to plugdev rules"
    sudo cp $SCRIPTPATH/99-uCtools.rules /etc/udev/rules.d/
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
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    echo "If user does not appear below, add user to plugdev group"
    less /etc/group | grep plugdev
}

config_rules;
