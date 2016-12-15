#!/bin/bash
#######################################################################
#######################################################################
##########                                                   ##########
########     MUST CALL WITH $ source scripts/fconfig !!!!!     ########
##########                                                   ##########
#######################################################################
#######################################################################

export LM_LICENSE_FILE=~/tools/lscc/license-ice.dat
export LM_LICENSE_FILE=$LM_LICENSE_FILE:~/tools/altera/14.0/license.dat

ICEDIRs=$(find $toolsdir/lscc/iCEcube2* -maxdepth 0 -type d)
#export ICEDIR=$(echo $ICEDIRs | sed 's/\([^ ]*\).* \(.*\)/\1/')  # first
export ICEDIR=$(echo $ICEDIRs | sed 's/\([^ ]*\).* \(.*\)/\2/')  # last
if [ -d "$toolsdir/altera" ]; then
    ALTERADIRs=$(find $toolsdir/altera/* -maxdepth 0 -type d)
    ALTERADIR=$(echo $ALTERADIRs | sed 's/\([^ ]*\).* \(.*\)/\2/')
else
    ALTERADIR=""
    echo "modelsim not installed"
fi

export LD_LIBRARY_PATH=
export LD_LIBRARY_PATH=$ICEDIR/LSE:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ICEDIR/LSE/bin/lin:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ICEDIR/sbt_backend/lib/linux/opt:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$ICEDIR/sbt_backend/bin/linux/opt/synpwrap:$LD_LIBRARY_PATH
if [ -n "$ALTERADIR" ]; then
    export LD_LIBRARY_PATH=$ALTERADIR/modelsim_ase/lib32:$LD_LIBRARY_PATH
fi

export FOUNDRY=$ICEDIR/LSE
export SYNPLIFY_PATH=$ICEDIR/synpbase
export SBT_DIR=$ICEDIR/sbt_backend

export DIAMOND_DIR=$toolsdir/lscc/programmer/3.2
export PATH=$PATH:$DIAMOND_DIR/bin/lin:$DIAMOND_DIR/ispfpga/bin/lin
export PATH=$PATH:$ICEDIR/synpbase/linux/lib

if [ -n "$ALTERADIR" ]; then
    alias vsim="$ALTERADIR/modelsim_ase/linux/vsim"
    alias quartus="$ALTERADIR/quartus/bin/quartus"
fi

#alias synplify=$ICEDIR/synpbase/linux/mbin/synplify
#alias synplify_pro=$ICEDIR/synpbase/bin/synplify_pro
alias synplify=$ICEDIR/sbt_backend/bin/linux/opt/synpwrap/synpwrap\ -gui
alias synpwrap=$ICEDIR/sbt_backend/bin/linux/opt/synpwrap/synpwrap
alias synthesis=$ICEDIR/LSE/bin/lin/synthesis
alias sbrouter=$ICEDIR/sbt_backend/bin/linux/opt/sbrouter
alias edifparser=$ICEDIR/sbt_backend/bin/linux/opt/edifparser
alias sbtplacer=$ICEDIR/sbt_backend/bin/linux/opt/sbtplacer
alias iCEcube2=$ICEDIR/iCEcube2

export PATH=$PATH:$toolsdir/flopoco

#ln -s -T proj_ice/stopsen_impl/stopsen.srr log.log
#ln -s -T ~/.config/LatticeSemi/programmer.log programmer.log

#$ICEDIR/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj proj/stopsen_syn.prj -log icelog.log

#$ICEDIR/LSE/bin/lin/synthesis –f proj/stopsen_lse.prj

#tclsh iCEcube2_flow.tcl
