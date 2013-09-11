#! /bin/sh -e
# Get AOL Server from BitBucket and build tarball.
# Created: Tue Aug 27 18:52:34 EDT 2013

ATAG=$(grep AOL_VERSION aol_vars.yml | cut -d ':' -f 2 | tr -d ' ')
#ATAG=3.5-pre1
#ACHECKOUT=aolserver_v35_bp
#ACHECKOUT=aolserver_v35_b11  # didn't have include/Makefile.global.in
ACHECKOUT=aolserver_v35_pre1
#ACHECKOUT=aolserver3_3

if [ ! -d aolserver ]; then 
  git clone https://github.com/aolserver/aolserver.git
fi

if [ ! -f aolserver-${ATAG}.tgz ]; then 
  (cd aolserver; git checkout ${ACHECKOUT})
  tar czvf aolserver-${ATAG}.tgz ./aolserver
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
if [ ! -d nsoracle ]; then
  git clone https://github.com/aolserver/nsoracle.git
fi
if [ ! -f nsoracle-${OTAG}.tgz ]; then
  tar czvf nsoracle-${OTAG}.tgz ./nsoracle
  rm -rf nsoracle
fi

