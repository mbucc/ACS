#! /bin/sh -e
# Package up the ACS tarball.
# Created: Mon Sep  2 15:31:23 EDT 2013

VERS=$(grep ACS_VERSION acs_vars.yml | cut -d ':' -f 2 | tr -d ' ')

# We want stuff to exand to acs subdir.
DEST=acs

DIRS="
bin
data
packages
parameters
spam
tcl
templates
users
www
"

FILES="
readme.txt
minify.sh
"

if [ ! -f acs-${VERS}.tgz ]; then 
    rm -rf $DEST
    mkdir $DEST
    for d in $DIRS ; do cp -Rp ../$d $DEST; done
    for f in $FILES; do cp -Rp ../$f $DEST; done
    tar czvf acs-${VERS}.tgz ./acs
    rm -rf $DEST
fi
