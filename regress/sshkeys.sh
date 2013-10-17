#! /bin/sh -e
# Created: Mon Oct 14 11:07:25 EDT 2013

if [ "x$1" = "x" ] ; then
  echo "Usage $0 <vars.txt>" 1>&2
  exit 1
fi

source $1

# Copy SSH key for Oracle user.
echo "Creating $ORACLE_USER_HOME/.ssh (if necessary) ..."
ssh \
  root@${ACS_IP_ADDRESS} \
  "(mkdir -p $ORACLE_USER_HOME/.ssh; chown $ORACLE_USER:$ORACLE_GROUP $ORACLE_USER_HOME/.ssh)"
echo "Copying over public key ..."
scp ./oracle_id_rsa.pub root@${ACS_IP_ADDRESS}:$ORACLE_USER_HOME/.ssh/authorized_keys
echo "Setting ownership of public key ..."
ssh \
  root@${ACS_IP_ADDRESS} \
  "chown $ORACLE_USER:$ORACLE_GROUP $ORACLE_USER_HOME/.ssh/authorized_keys"

# Copy SSH key for AOL Server user (for restart on restoring data).
echo "Creating $AOL_HOME/.ssh (if necessary) ..."
ssh \
  root@${ACS_IP_ADDRESS} \
  "(mkdir -p $AOL_HOME/.ssh; chown $AOL_SERVER_USER:$WEB_GROUP $AOL_HOME/.ssh)"
echo "Copying over public key ..."
scp ./oracle_id_rsa.pub root@${ACS_IP_ADDRESS}:$AOL_HOME/.ssh/authorized_keys
echo "Setting ownership of public key ..."
ssh \
  root@${ACS_IP_ADDRESS} \
  "chown $AOL_SERVER_USER:$WEB_GROUP $AOL_HOME/.ssh/authorized_keys"

