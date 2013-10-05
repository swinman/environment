#!/bin/sh

#! chmod 755 %; %

# make a diff file and zip the change files one git tag to the next
# this works on linux
# got to the head of the git directory
# call the script with rel_path/zip_git zipname git_original git_updated

diff_ext=_change_log
zip_readme=ZIP_GIT_README.txt

echo "\
Change set from GIT ref:\n\
##############################################\n\n\
     $2     -->>     $3\n\n\
##############################################\n\
including all changed files in \n$3:" > $zip_readme
git log --pretty=format:'%H' -n 1 >> $zip_readme
echo "" >> $zip_readme
date >> $zip_readme
echo "\
\n\n\
zip file auto-generated using:\n\n\
$ git checkout $2\n\
$ git diff $2 $3 > $1$diff_ext\n\
$ cat $1$diff_ext | \\ \n\
    grep \"diff --git\" | \\ \n\
    sed 's/diff\ --git\ .*\ b\///g' | \\ \n\
    zip $1 -@ $1$diff_ext $zip_readme\n\
$ rm $1$diff_ext\n\
$ rm $zip_readme\n\n\
script by swinman 2013-05-11\n" >> $zip_readme

git checkout $3
git diff $2 $3 > $1$diff_ext
cat $1$diff_ext | grep "diff --git" | sed 's/diff\ --git\ .*\ b\///g' |
 zip $1 -@ $1$diff_ext $zip_readme

#cleanup
rm $zip_readme
