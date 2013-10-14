#! /bin/sh -e
# Created: Mon Oct 14 11:07:25 EDT 2013

if [ "x$1" = "x" ] ; then
  echo "Usage $0 <vars.txt>" 1>&2
  exit 1
fi

FN=$1

HOST=$(grep  "^ACS_IP_ADDRESS="   $FN | cut -d = -f 2)
USER=$(grep  "^ORACLE_USER="      $FN | cut -d = -f 2)
GROUP=$(grep "^ORACLE_GROUP="     $FN | cut -d = -f 2)
HOME=$(grep  "^ORACLE_USER_HOME=" $FN | cut -d = -f 2)

echo "Creating $HOME/.ssh (if necessary) ..."
ssh root@${HOST} "(mkdir -p $HOME/.ssh; chown $USER:$GROUP $HOME/.ssh)"
echo "Copying over public key ..."
scp ./oracle_id_rsa.pub root@${HOST}:$HOME/.ssh/authorized_keys
echo "Setting ownership of public key ..."
ssh root@${HOST} "chown $USER:$GROUP $HOME/.ssh/authorized_keys"
