#! /bin/sh -e
# Created: Mon Oct 14 12:11:52 EDT 2013
# List yml files that are not referenced in playbook.

PLAYBOOK=playbook.yml
for f in *.yml ; do
  if [ "$f" = "test.yml"  ] ; then continue ; fi
  if [ "$f" = "$PLAYBOOK" ] ; then continue ; fi
  if ! grep $f $PLAYBOOK > /dev/null; then
    echo $f
  fi
done
