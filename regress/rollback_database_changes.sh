#! /bin/sh -e
# Created: Mon Oct 14 23:01:01 EDT 2013

source vars.txt

SSH="ssh -i oracle_id_rsa $ORACLE_USER@$ACS_IP_ADDRESS"

# Create RMAN script to roll back to before unit tests.
# 
# Notes: 
#
#   * resetlogs is needed because we don't use the all of the redo logs; we
#     are only recovering up to the restore point.
#
#   * Using resetlogs creates a new incarnation of the database; "Oracle
#     archives the current redo log and clears them all by setting the log
#     sequence number to 1"
#     http://www.dba-oracle.com/t_rman_71_recover_previous_incarnation.htm
#

cat > restore.rman << EOF
connect target /
shutdown immediate;
startup mount;
reset database to incarnation 2;
run
{
    set until restore point unit_test_start;
    restore database;
    recover database;
}
alter database open resetlogs;
EOF
scp -i oracle_id_rsa restore.rman $ORACLE_USER@$ACS_IP_ADDRESS:~

# Run RMAN restore script.
${SSH} ". ./.profile ; rman @restore.rman"

# Restart AOL Server.
ssh -i oracle_id_rsa $AOL_SERVER_USER@$ACS_IP_ADDRESS /usr/local/bin/restart-aolserver
