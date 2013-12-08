#! /bin/sh -e
# Created on Sun Nov 10 10:55:07 EST 2013 
# by Mark Bucciarelli <mkbucc@gmail.com>
# Merge static files, put MD5 in filename, and update properties file.

DIR=www/static

# JavaScript
TMPFN=tmp.js
files="
reveal.js
pagination.js
acs.js
"

rm -f $TMPFN
for f in $files; do
	cat $DIR/$f >> $TMPFN
done

FN=acs-$(md5sum $TMPFN | awk '{print $1}').js

cp $TMPFN $DIR/$FN
PFN=$(find parameters -name "*.tcl" | xargs grep -l "acs\(\-[^.]\+\)\?\.js")
cp "$PFN" "$PFN.$(date +%F_%H-%M-%S)"
cat "$PFN" | sed "s;acs\(\-[^.]\+\)\?\.js;$FN;" > mkb.tcl
mv mkb.tcl "$PFN"

if ! grep $FN $PFN > /dev/null ; then
        echo $0 ERROR, $FN not in $PFN >&2
        exit 1
fi

# CSS
TMPFN=tmp.css
files="
reveal.css
serif.css
acs.css
"

rm -f $TMPFN
for f in $files; do
	cat $DIR/$f >> $TMPFN
done

FN=acs-$(md5sum $TMPFN | awk '{print $1}').css

cp $TMPFN $DIR/$FN
PFN=$(find parameters -name "*.tcl" | xargs grep -l "acs\(\-[^.]\+\)\?\.css")
cp "$PFN" "$PFN.$(date +%F_%H-%M-%S)"
cat "$PFN" | sed "s;acs\(\-[^.]\+\)\?\.css;$FN;" > mkb.tcl
mv mkb.tcl "$PFN"

if ! grep $FN $PFN > /dev/null ; then
        echo $0 ERROR, $FN not in $PFN >&2
        exit 1
fi
