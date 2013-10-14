#! /bin/sh -e
# Created: Mon Oct 14 12:15:59 EDT 2013
# List unused yml variables.

for f in *_vars.yml ; do
  for v in $(grep "^[A-Z ]\+" $f | cut -d : -f 1); do
    if grep $v --exclude $f *.yml > /dev/null ; then continue ; fi
    if grep $v              *.j2  > /dev/null ; then continue ; fi
    if grep $v              *.sh  > /dev/null ; then continue ; fi
    echo $f: $v is not used.
  done
done
