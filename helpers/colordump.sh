# Dump out colors
if [ -z $1 ]; then
    num_colors=256
else
    num_colors=$1
fi

x=`tput op` y=`printf %76s`;
for i in $(seq 0 $(($num_colors-1))); do
    o=00$i;
    echo -e ${o:${#o}-3:3} `tput setaf $i;
    tput setab $i`${y// /=}$x;
done
