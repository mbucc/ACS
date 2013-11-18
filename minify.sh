#! /bin/sh -e
# Created on Sun Nov 10 10:55:07 EST 2013 
# by Mark Bucciarelli <mkbucc@gmail.com>
# Merge static files, put MD5 in filename, and update properties file.

DIR=www/static
TMPFN=tmp.js

files="
pagination.js
acs.js
"

rm -f $TMPFN
for f in $files; do
	cat $DIR/$f >> $TMPFN
done

FN=acs-$(md5sum $TMPFN | awk '{print $1}').js

if [ ! -f $DIR/$FN ] ; then
	cp $TMPFN $DIR/$FN
fi

for f in $(find parameters -type f) ; do
	cat "$f" | sed "s;acs\.js;$FN;" > mkb.tcl
	mv mkb.tcl "$f"
done
