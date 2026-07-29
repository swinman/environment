#!/bin/bash
# use to make ctags and taghighlight files
# if you want to provide a root directory for your code
# that is different from the calling directory, use
# an additional parameter when you call the script

if [ -n "$1" ]; then
    SRC_DIR=$(pwd)/$1
    echo "SRC_DIR set to $SRC_DIR"
else
    SRC_DIR=$(pwd)
fi

# pack/plugins/start, not bundle/.  config_vim.sh installs plugins as native
# vim 8 packages and retired the pathogen bundle/ layout, so both of these
# pointed at a directory that no longer exists - which made the taghighlight
# block at the bottom silently skip rather than fail.
if [ "$OS" = "windows" ]; then
    VIMDIR=~/vimfiles
else
    VIMDIR=~/.vim
fi
CTAGS=ctags
TAGHL=$VIMDIR/pack/plugins/start/taghighlight/plugin/TagHighlight/TagHighlight.py

# universal-ctags' VHDL parser gives up on the architecture's declarative
# region once it has passed a run of `component` declarations.  In
# stopsen's fpga/main_top.vhd it tags the entity fine - 81 ports, 38 generics
# - then emits nothing for the 54 signals and 2 types that follow the seven
# component blocks.  The result looks like a highlighting bug rather than a
# tagging one: a signal is coloured only if some *other* file happens to
# declare the same name, since syn keyword applies to the whole buffer.  Hence
# roughly half of them green and half white.
#
# These rules add the signals back through ctags' own regex mechanism, so they
# land in the tags file and :tag works on them, rather than being patched into
# the highlight file afterwards.
#
# One rule per name position, because a ctags regex yields a single tag per
# line: 25% of declarations here name two or more signals.  Four covers 99% of
# them (811 declare one name, 262 two, 14 three, 6 four, and a thin tail out to
# thirteen).
#
# [[:space:]] rather than [ \t]: the rules are passed unquoted so the shell
# splits them into one argument each, which a pattern containing a literal
# space would not survive.
_vhdl_id='[a-zA-Z0-9_]+'
_vhdl_sp='[[:space:]]*'
_vhdl_pre="^${_vhdl_sp}signal[[:space:]]+"
_vhdl_sep="${_vhdl_id}${_vhdl_sp},${_vhdl_sp}"
VHDL_SIGNAL_RULES="
--regex-VHDL=/${_vhdl_pre}(${_vhdl_id})/\1/s,signal/i
--regex-VHDL=/${_vhdl_pre}${_vhdl_sep}(${_vhdl_id})/\1/s,signal/i
--regex-VHDL=/${_vhdl_pre}${_vhdl_sep}${_vhdl_sep}(${_vhdl_id})/\1/s,signal/i
--regex-VHDL=/${_vhdl_pre}${_vhdl_sep}${_vhdl_sep}${_vhdl_sep}(${_vhdl_id})/\1/s,signal/i
"

if hash $CTAGS 2>/dev/null; then
    echo "Make ctags list"
    echo "ctags is version $(ctags --version)"
    rm -f $SRC_DIR/tags
    # --languages=-JSON because ctags tags every element of a json array.
    # A 12MB data file in stopsen's testing/datafiles produced 507,968 tags
    # named array:sigs.N and a 74MB tags file, against 3,791 real tags from
    # the .vhd sources.  Dropping the parser takes that to 596KB.  Nothing
    # navigates to a json key by tag, so there is nothing to lose.
    cd $SRC_DIR && $CTAGS -R --exclude="*~" --exclude=".git" \
        --languages=-JSON --langmap=c:+.npl $VHDL_SIGNAL_RULES
    if [ -f $SRC_DIR/tags ]; then
        # Drop the tags for bare type names, which are noise to jump to.
        #
        # One grep, where this used to be a loop of `sed -i` blanking the
        # matching lines followed by a second `sed -i` deleting the blanks.
        # Both failed outright under BSD sed: -i there reads its argument as
        # the backup suffix, so it swallowed the script and died on the
        # filename, and \s is a GNU extension that BSD sed matches as a
        # literal s.  A POSIX ERE with [[:space:]] behaves the same under
        # either sed, and removing the lines outright leaves no blanks to
        # clean up afterwards.
        #
        # cat-then-rm rather than mv, so the tags file keeps its permissions.
        echo "Dropping type-name tags from $SRC_DIR/tags"
        grep -v -E "^(bool|char|int|uint8_t|uint16_t|uint32_t)[[:space:]]" \
            $SRC_DIR/tags > $SRC_DIR/tags.tmp \
            && cat $SRC_DIR/tags.tmp > $SRC_DIR/tags
        rm -f $SRC_DIR/tags.tmp
    fi
fi

if [ -e $TAGHL ]; then
    echo "Make taghighlight files"
    rm -f $SRC_DIR/types_*.taghl
    cd $SRC_DIR && python3 $TAGHL \
        --use-existing-tagfile --ctags-file=$SRC_DIR/tags \
        --source-root=$SRC_DIR
fi

# TagHighlight's data/kinds.txt lists only the twelve VHDL kinds exuberant
# ctags emitted.  universal-ctags also reports signals, ports, generics,
# architectures, processes, variables and aliases, and those are silently
# dropped - 3225 of stopsen's 3791 VHDL tags, including every signal and
# port, which are the ones worth highlighting in VHDL.
#
# There is no user override for that file: config.py derives DataDirectory
# from the module's own __file__, so the only ways in are patching a plugin
# that config_vim.sh re-clones, or generating the missing groups here.
#
# Names are claimed by the first kind that declares them, so a name appearing
# as both a signal and a port lands in one group rather than being highlighted
# twice with different colours.
# Same gap on the python side: TagHighlight's kinds.txt maps c, f, i, m and v,
# while universal-ctags also reports 'I' (a module defined in another file) and
# 'Y' (a class, variable, function or module from another module).  Those are
# the imported names, and they were dropped with the same "Unrecognised kind"
# line - which is why nothing an import brought in was highlighted.
if [ -f $SRC_DIR/types_py.taghl ]; then
    echo "Adding the python import kinds TagHighlight drops"
    awk -F'\t' '
        /^!/ { next }
        $2 ~ /\.py$/ {
            kind = ""
            for (i = 4; i <= NF; i++) if ($i ~ /^[a-zA-Z]$/) { kind = $i; break }
            if ((kind != "I" && kind != "Y") || ($1 in seen)) next
            seen[$1] = 1
            words = words " " $1
            if (++n % 40 == 0) { print "syn keyword CTagsImport" words; words = "" }
        }
        END { if (words != "") print "syn keyword CTagsImport" words }
    ' $SRC_DIR/tags >> $SRC_DIR/types_py.taghl
fi

if [ -f $SRC_DIR/types_vhdl.taghl ]; then
    echo "Adding the VHDL kinds TagHighlight drops"
    awk -F'\t' '
        BEGIN {
            grp["s"] = "CTagsSignal";  grp["q"] = "CTagsPort"
            grp["g"] = "CTagsGeneric"; grp["a"] = "CTagsArchitecture"
            grp["Q"] = "CTagsProcess"; grp["v"] = "CTagsVariable"
            grp["A"] = "CTagsAlias"
        }
        /^!/ { next }
        $2 ~ /\.vhdl?$/ {
            kind = ""
            for (i = 4; i <= NF; i++) if ($i ~ /^[a-zA-Z]$/) { kind = $i; break }
            if (!(kind in grp) || ($1 in seen)) next
            seen[$1] = 1
            g = grp[kind]
            words[g] = words[g] " " $1
            # chunked the way TagHighlight chunks its own output, rather than
            # emitting one unbounded line per group
            if (++n[g] % 40 == 0) { print "syn keyword " g words[g]; words[g] = "" }
        }
        END { for (g in words) if (words[g] != "") print "syn keyword " g words[g] }
    ' $SRC_DIR/tags >> $SRC_DIR/types_vhdl.taghl
fi
