# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
export ORACLE_BASE=/home/oracle/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/11.2.0/dbhome_2
export LD_LIBRARY_PATH=$ORACLE_HOME/lib
export ORACLE_SID=ora11
export ORA_NLS11=$ORACLE_HOME/nls/data
export JAVA_HOME=/usr/java/latest

export PATH=$JAVA_HOME/bin:$PATH:$ORACLE_HOME/bin
CLASSPATH=$ORACLE_HOME/ucp/lib/ucp.jar:$ORACLE_HOME/jdbc/lib/ojdbc6.jar:$CLASSPATH
export CLASSPATH
export XDB_HOL="/home/oracle/Desktop/Database*/XMLDB*/2011"

set -o vi

cat ~/Desktop/README.txt

/sbin/ifconfig | grep "inet addr"

umask 022
