#!/bin/sh

# for ctags, certian typedefs are showing up as structure members
# so kind:m is appearing instead of kind:t
#
# option 1) find and fix everywhere this is happening in the code
# option 2) remove all the refs to known types in the ctags file


sed_structure_types() {
    var=$1
    macro="__I"
    for fn in $(grep -m 1 -r --include="*.[chsCHS]" "$macro *$var *:" | sed 's/:.*//'); do
        echo "fixing $var in $fn"
        grep "$macro *$var *:" $fn
        sed -i "s/$var *:/$var _unused :/" $fn
    done
}

sed_structure_types uint8_t;
sed_structure_types uint16_t;
sed_structure_types uint32_t;
