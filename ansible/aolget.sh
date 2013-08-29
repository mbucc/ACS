#! /bin/sh -e
# Get AOL Server from BitBucket and build tarball.
# Created: Tue Aug 27 18:52:34 EDT 2013

ATAG=3.5.0

if [ ! -f aolserver-${ATAG}.tgz ]; then 
  git clone https://github.com/aolserver/aolserver.git
  (cd aolserver; git checkout aolserver_v35_bp)
  tar czvf aolserver-${ATAG}.tgz ./aolserver
  rm -rf aolserver
fi

TK=tk8.4.20-src.tar.gz
TCL=tcl8.4.20-src.tar.gz
if [ ! -f ${TCL} ]; then 
  ftp -a ftp://ftp.tcl.tk/pub/tcl/tcl8_4/${TCL} -o ${TCL}
fi
if [ ! -f ${TK} ]; then 
  ftp -a ftp://ftp.tcl.tk/pub/tcl/tcl8_4/${TK} -o ${TK}
fi


# Get the Oracle driver.  Version is in README.
OTAG=2.7
if [ ! -f nsoracle-${OTAG}.tgz ]; then
  git clone https://github.com/aolserver/nsoracle.git
  tar czvf nsoracle-${OTAG}.tgz ./nsoracle
  rm -rf nsoracle
fi

