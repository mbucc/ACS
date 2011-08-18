#!/bin/ksh
umask 007
echo "run: `date`" >> /tmp/q-intranet.log
/web/arsdigita/bin/q.pl $* >> /tmp/q-intranet.log 2>&1
