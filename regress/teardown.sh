#! /bin/sh -e
# Created: Mon Oct 14 23:01:01 EDT 2013

source vars.txt

SSH="ssh -i oracle_id_rsa $ORACLE_USER@$ACS_IP_ADDRESS"

# Create RMAN script to roll back to before unit tests.
cat > restore.rman << EOF
connect target /
shutdown immediate;
startup mount;
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
#$ rman target /
${SSH} ". ./.profile ; rman @restore.rman"
