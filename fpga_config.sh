#!/bin/bash
#######################################################################
#######################################################################
##########                                                   ##########
########     MUST CALL WITH $ source scripts/fconfig !!!!!     ########
##########                                                   ##########
#######################################################################
#######################################################################

# Direct source only, on purpose.  A fresh shell carries NO fpga / uC tools:
# this file returns immediately when sourced from another file (an rc chain
# at shell init), and provides everything only when sourced directly -
# `source ~/software/environment/fpga_config.sh`, or the uctools alias.  So
# `make syn` in ../stopsen fails loudly in a new shell instead of leaning on
# whatever environment the shell happens to carry.
#
# That failure is a reminder, and the intended fix lives in stopsen, not
# here: commit a discovery tool there (a make fragment or a script the
# Makefile sources) that finds iCEcube2 / Diamond under $toolsdir and sets
# FOUNDRY, SBT_DIR, SYNPLIFY_PATH, LM_LICENSE_FILE and LD_LIBRARY_PATH for
# the build's own processes - the way liblusam's ccdb.py generates
# compile_commands.json at postbuild.  The env then travels with the build,
# so ssh / cron / bare non-interactive shells all work, and LD_LIBRARY_PATH
# never leaks into interactive shells.  stopsen is the only repo doing FPGA
# work; until that tool exists, uctools is the manual fallback.
#
# BASH_SOURCE[1] is set only when the `source` call itself came from a
# sourced file (.bashrc -> _aliases -> here); typed at a prompt the depth is
# one and it is empty.  Executed rather than sourced it is also empty, and
# the mac branch below exits for that case.
if [ -n "${BASH_SOURCE[1]}" ]; then
    return 0
fi

# No-op on mac.  Everything below is the x86 Linux iCEcube2 / Diamond flow -
# LSE and sbt_backend are Linux ELF, the licensing is FlexLM node-locked, and
# LD_LIBRARY_PATH is ignored by macOS anyway (it uses DYLD_LIBRARY_PATH).  The
# find on line one of the body also fails outright, since $toolsdir/lscc does
# not exist here.  FPGA builds happen on a remote machine instead; see TODO.md.
#
# arm-none-eabi is no longer a reason to source this on mac either: the
# gcc-arm-embedded cask puts it on PATH directly.
#
# `return` when sourced, which is the normal path via the uctools alias, and
# `exit` when run directly.
if [ "$OS" = "mac" ]; then
    echo "fpga_config.sh: linux only, skipping (FPGA builds run remotely)"
    return 0 2>/dev/null || exit 0
fi

export LM_LICENSE_FILE=~/tools/lscc/license-ice.dat
#export LM_LICENSE_FILE=$LM_LICENSE_FILE:~/tools/altera/14.0/license.dat

ICEDIRs=$(find $toolsdir/lscc/iCEcube2* -maxdepth 0 -type d)
#export ICEDIR=$(echo $ICEDIRs | sed 's/\([^ ]*\).* \(.*\)/\1/')  # first
export ICEDIR=$(echo $ICEDIRs | sed 's/\([^ ]*\).* \(.*\)/\2/')  # last
ALTERADIR=""
if [ -d "$toolsdir/intelFPGA" ]; then
    INTELDIRs=$(find $toolsdir/intelFPGA/* -maxdepth 0 -type d)
    INTELDIR=$(echo $INTELDIRs | sed 's/\([^ ]*\).* \(.*\)/\2/')
else
    echo "modelsim not installed"
fi

export FOUNDRY=$ICEDIR/LSE
export SYNPLIFY_PATH=$ICEDIR/synpbase
export SBT_DIR=$ICEDIR/sbt_backend
export DIAMOND_DIR=$toolsdir/lscc/programmer/3.2

# PATH / LD_LIBRARY_PATH appends run once per environment: nested shells
# (tmux, bash inside bash) inherit them along with UCTOOLS_ON and skip this
# block, so re-sourcing only re-defines the aliases below.  LD_LIBRARY_PATH
# is prepended to, not cleared, so any prior value survives.
if [ -z "$UCTOOLS_ON" ]; then
    export LD_LIBRARY_PATH=$ICEDIR/LSE${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
    export LD_LIBRARY_PATH=$ICEDIR/LSE/bin/lin:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$ICEDIR/sbt_backend/lib/linux/opt:$LD_LIBRARY_PATH
    export LD_LIBRARY_PATH=$ICEDIR/sbt_backend/bin/linux/opt/synpwrap:$LD_LIBRARY_PATH
    if [ -n "$ALTERADIR" ]; then
        export LD_LIBRARY_PATH=$ALTERADIR/modelsim_ase/lib32:$LD_LIBRARY_PATH
    fi

    export PATH=$PATH:$DIAMOND_DIR/bin/lin:$DIAMOND_DIR/ispfpga/bin/lin
    export PATH=$PATH:$ICEDIR/synpbase/linux/lib
    export PATH=$PATH:$toolsdir/arm-none-eabi/bin
    export PATH=$PATH:$toolsdir/flopoco
    export PATH=$PATH:$toolsdir

    export UCTOOLS_ON=1
fi

if [ -n "$INTELDIR" ]; then
    alias vsim="$INTELDIR/modelsim_ase/linux/vsim"
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

#ln -s -T proj_ice/stopsen_impl/stopsen.srr log.log
#ln -s -T ~/.config/LatticeSemi/programmer.log programmer.log

#$ICEDIR/sbt_backend/bin/linux/opt/synpwrap/synpwrap -prj proj/stopsen_syn.prj -log icelog.log

#$ICEDIR/LSE/bin/lin/synthesis –f proj/stopsen_lse.prj

#tclsh iCEcube2_flow.tcl
