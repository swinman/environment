#!/bin/bash

# call with -y as argument and it will automatically push / pull when it can

get_git_repo() {
    local dir_trail=$1
    local yes=$2
    local dir=$(echo $dir_trail | sed 's/\/$//')
    local name=$(echo $dir | sed 's/\/$//' | sed 's/.*\///')
    local branch=$(cd $dir && git status | grep "On branch " | sed 's/On branch //')

    echo "Fetching from $name, on branch $branch"
    cd $dir && git fetch
    local behind=$(cd $dir && git log --oneline ..origin/$branch | wc -l)
    local ahead=$(cd $dir && git log --oneline origin/$branch.. | wc -l)
    if [ "$behind" -eq "0" ]; then
        if [ "$ahead" -gt "0" ]; then
            echo "$name is ahead of origin/$branch by $ahead commits, push"
            if [ "$yes" = "-y" ]; then
                cd $dir && git push
            else
                read -p "y/[n]" response
                if [ "$response" = "y" ]; then
                    cd $dir && git push
                fi
            fi
        else
            echo "$name is up to date with origin/$branch"
        fi
    elif [ "$ahead" -eq "0" ]; then
        echo "$name is behind origin/$branch by $behind commits, merge"
        if [ "$yes" = "-y" ]; then
            cd $dir && git merge origin/$branch
        else
            read -p "y/[n]" response
            if [ "$response" = "y" ]; then
                cd $dir && git merge origin/$branch
            fi
        fi
    else
        echo "$branch and origin/$branch have $ahead and $behind commits"
    fi
    echo
}

all=$1
starting_dir=$(pwd)

for subdir in $(ls -d */); do
    get_git_repo $starting_dir/$subdir $all
done
