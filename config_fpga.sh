#!/bin/sh

# --------------------- DEFINE SEVERAL FUNCTIONS --------------------- #
# download the quartus web edition tool


# add to path ....
# PATH DEFAULT=\${PATH}:$toolsdir/lscc/iCEcube2.2014.04/

# the following aliases are part of _bash_aliases
#alias vsim='$toolsdir/altera/*/modelsim_ase/linux/vsim'
#alias quartus='$toolsdir/altera/*/quartus/bin/quartus'

#get_avr_tools() {
#    sudo apt-get install gdb-avr -y
    # try avr-gdb and avr-run ... doesn't seem like there is much here..
#    sudo apt-get install gdb-doc -y
#}


# --------------------- SETUP SCRIPT --------------------- #
########## RUN WHATEVER YOU WANT DOWN HERE ############

echo "==================== config_fpga.sh ===================="
# add plugdev rules for accessing atmel devices
#get_avr_tools;
echo "=============== END: config_fpga.sh ===================="
