restore:
	( \
	  source ./vars.txt ; \
	  ssh -i oracle_id_rsa \
	  	$$ORACLE_USER@$$ACS_IP_ADDRESS \
		$$ORACLE_HOME/config/scripts/restore.sh \
	)

backup:
	( \
	  source ./vars.txt ; \
	  ssh -i oracle_id_rsa \
	  	$$ORACLE_USER@$$ACS_IP_ADDRESS \
		$$ORACLE_HOME/config/scripts/backup.sh \
	)

# Run once to setup SSH keys.  Used for test setup/teardown; Before running
# tests, we back stuff up, then after each test is done we restore.)
setup_sshkey: vars.txt
	./setup_sshkey.sh vars.txt
	
vars.txt: ../ansible/ora_vars.yml ../ansible/acs_vars.yml expand_yml.py
	python expand_yml.py ../ansible/ora_vars.yml > t.txt
	python expand_yml.py ../ansible/acs_vars.yml >> t.txt
	mv t.txt vars.txt
