# $ gem install pry
all:
	@echo "*******************************************************"
	@echo ""
	@echo "    0. Create key for root in ../id_rsa"
	@echo ""
	@echo "    1. Run ssh-keygen to create oracle_id_rsa[.pub]"
	@echo ""
	@echo "    2. Turn off iptables on target: service iptables stop"
	@echo ""
	@echo "    3. Copy over SSH keys for nsadmin and oracle user and"
	@echo "       create rollback point in database.  One time only."
	@echo ""
	@echo "            $$ make init"
	@echo ""
	@echo "    4. Run tests."
	@echo ""
	@echo "            $$ make test"
	@echo ""
	@echo ""
	@echo "Alternatively, "
	@echo ""
	@echo "    Create some users, news articles and comments:"
	@echo ""
	@echo "            $$ make newsdata"
	@echo ""
	@echo ""
	@echo "    Rollback all database to rollback point set in init"
	@echo ""
	@echo "            $$ make rollback"
	@echo ""
	@echo ""
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

rollback: vars.txt
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
