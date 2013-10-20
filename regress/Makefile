# $ gem install pry
all:
	@echo "*******************************************************"
	@echo ""
	@echo "    1. Run ssh-keygen to create oracle_id_rsa[.pub]"
	@echo ""
	@echo "    2. Turn off iptables on target: service iptables stop"
	@echo ""
	@echo "    3. One-time setup."
	@echo ""
	@echo "            init"
	@echo ""
	@echo "    4. Run tests."
	@echo ""
	@echo "            test"
	@echo ""
	@echo "*******************************************************"
	@exit 1

init:
	make sshkeys
	make backup_database_and_set_rollback_point

test: 
	ruby test_user_registration.rb
	make rollback_database_changes

sshkeys: vars.txt oracle_id_rsa.pub
	./sshkeys.sh vars.txt
	
backup_database_and_set_rollback_point: vars.txt
	./backup_database_and_set_rollback_point.sh

rollback_database_changes: vars.txt
	./rollback_database_changes.sh

vars.txt: \
		../ansible/ora_vars.yml \
		../ansible/acs_vars.yml \
		../ansible/aol_vars.yml \
		expand_yml.py
	python expand_yml.py ../ansible/ora_vars.yml > t.txt
	python expand_yml.py ../ansible/acs_vars.yml >> t.txt
	python expand_yml.py ../ansible/aol_vars.yml >> t.txt
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
