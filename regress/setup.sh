#! /bin/sh -e

source vars.txt

SSH="ssh -i oracle_id_rsa $ORACLE_USER@$ACS_IP_ADDRESS"

# Create a full backup.
${SSH} $ORACLE_HOME/config/scripts/backup.sh

# Create a restore point so we can undo test data.
cat > restore_point.sql << EOF
CREATE RESTORE POINT unit_test_start;
exit;
EOF
scp -i oracle_id_rsa restore_point.sql $ORACLE_USER@$ACS_IP_ADDRESS:~
${SSH} ". ./.profile ; sqlplus system/$ORA_SYSTEM_PASSWORD @restore_point.sql"
