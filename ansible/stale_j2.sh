#! /bin/sh -e
# Created: Mon Oct 14 12:28:54 EDT 2013
# List unused template files.

for f in *.j2 ; do
  if grep $f *.yml > /dev/null; then continue; fi
  echo $f is not used.
done
