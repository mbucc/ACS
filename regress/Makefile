all:
	@echo "*******************************************************"
	@echo ""
	@echo "    1. Run ssh-keygen to create oracle_id_rsa[.pub]"
	@echo ""
	@echo "    2. Run targets in this order:"
	@echo ""
	@echo "            sshkeys"
	@echo "            setup"
	@echo "            test"
	@echo ""
	@echo "    3. When done, to reset run the targets:"
	@echo ""
	@echo "            teardown"
	@echo "            clean"
	@echo ""
	@echo "*******************************************************"
	@exit 1

test: 
	ruby test_user_registration.rb

teardown: vars.txt
	./teardown.sh

setup: vars.txt
	./setup.sh

sshkeys: vars.txt oracle_id_rsa.pub
	./sshkeys.sh vars.txt
	
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

clean:
	rm -f vars.txt
	rm -f restore.rman
	rm -f restore_point.sql
