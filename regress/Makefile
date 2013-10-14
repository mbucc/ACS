all:
	@echo "*******************************************************"
	@echo ""
	@echo "    1. Run ssh-keygen to create oracle_id_rsa[.pub]"
	@echo ""
	@echo "    2. Run targets in this order:"
	@echo ""
	@echo "            setup_sshkey"
	@echo "            backup"
	@echo "            test"
	@echo ""
	@echo "    3. When tests pass, run:"
	@echo ""
	@echo "            restore"
	@echo "            clean"
	@echo ""
	@echo "*******************************************************"
	@exit 1

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

setup_sshkey: vars.txt oracle_id_rsa.pub
	./setup_sshkey.sh vars.txt
	
vars.txt: ../ansible/ora_vars.yml ../ansible/acs_vars.yml expand_yml.py
	python expand_yml.py ../ansible/ora_vars.yml > t.txt
	python expand_yml.py ../ansible/acs_vars.yml >> t.txt
	mv t.txt vars.txt

oracle_id_rsa.pub:
	@echo "*******************************************************"
	@echo ""
	@echo "    Run ssh-keygen to create oracle_id_rsa and"
	@echo "    oracle_id_rsa.pub"
	@echo ""
	@echo "*******************************************************"
	@exit 1
