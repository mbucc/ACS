#! /bin/sh -e
# Get AOL Server tarballs from Sourceforge.
# Created: Tue Aug 27 18:52:34 EDT 2013

files="
http://downloads.sourceforge.net/project/aolserver/nssha1/nssha1-0.1/nssha1-0.1.tar.gz
http://downloads.sourceforge.net/project/aolserver/nscache/nscache-1.5/nscache-1.5.tar.gz
http://downloads.sourceforge.net/project/aolserver/nsopenssl/nsopenssl-2.1a/nsopenssl-2.1a.tar.gz
http://downloads.sourceforge.net/project/aolserver/AOLserver/4.5.2/aolserver-4.5.2-rc0.tar.gz
https://github.com/aolserver/nssha1/archive/master.zip
"

for f in $files; do
  fn=$(echo $f | awk -F "/" '{print $NF}')
  if [ ! -f $fn ] ; then 
    echo "curl -L $f > $fn"
    curl -L $f > t.tar.gz
    mv t.tar.gz $fn
    if [ "$fn" = "master.zip" ] ; then 
      mv master.zip nssha1-master.zip
    fi
  else
    echo $fn already downloaded.
  fi
done
