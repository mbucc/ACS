# /admin/acceptance/tests/gp-acceptance-test.tcl

ad_page_contract {
    automated general permissions acceptance test (tests pl/sql procs
    and data model)

    requires:
    o existence of system user
    o existence of site-wide admin group
    o existence of non-system user

    @author richardl@arsdigita.com
    @creation-date 2000 March 16
    @cvs-id  gp-acceptance-test.tcl,v 1.4.2.9 2000/09/22 01:34:17 kevin Exp
} {

}

# modified by jwong@arsdigita.com on 18 Jul 2000 for ACS 3.4

# all table names are inconsistently capitalized to test the to_lower stuff in PL/SQL
set html "
[ad_header "General Permissions acceptance test"]
<h2>General Permissions acceptance test</h2>
Running...
<ul>
"

set system_user_id [db_string admin_acceptance_gp_user_id_select "select user_id from users where email = 'system'"]
set reg_user_id [db_string admin_acceptance_gp_reg_user_id_select "select max(user_id) from users where email <> 'system'"]

# test read permissions for a user
db_exec_plsql admin_acceptance_test_gp_read_permission_test "begin :1 := ad_general_permissions.grant_permission_to_user($reg_user_id,'read',1,'TEST_TabLE'); end;"
append html "<li>Created user read permission record."

if { [ad_user_has_row_permission_p $reg_user_id "read" 1 "TEST_TABLE"] } {
    append html "<li>User test passed."
} else {
    append html "<li><font color=red>User test failed.</font>"
}

# test revoking permission
set permission_id [db_string permission_id_select "select ad_general_permissions.user_permission_id($reg_user_id,'read',1,'TesT_TABLE')
                                               from dual"]
db_dml admin_acceptance_test_gp_permission_revoke "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $reg_user_id "read" 1 "TEST_TABLE"] } {
    append html "<li>User revocation test passed."
} else {
    append html "<li><font color=red>User revocation test failed.</font>"
}

# test site-wide admin
if { [ad_user_has_row_permission_p $system_user_id "read" 1 "TEST_TABLE"] } {
    append html "<li>Site-wide admin user test passed."
} else {
    append html "<li><font color=red>Site-wide admin User test failed.</font>"
}

# put reguser into the employees group
set employee_group_id [db_string admin_acceptance_tests_gp_group_id_select "select group_id from user_groups
                                                   where group_name = 'Employees'"]

db_dml admin_acceptance_gp_group_map_insert "insert into user_group_map(group_id, user_id, registration_date,mapping_user,mapping_ip_address)
               values($employee_group_id, $reg_user_id, sysdate, $system_user_id, '[ns_conn peeraddr]')"

db_exec_plsql admin_acceptance_gp_group_group_test  "begin :1 := ad_general_permissions.grant_permission_to_group($employee_group_id,'read',1,'TEST_tabLE'); end;"

append html "<li>Created group read permission record."

if { [ad_user_has_row_permission_p $reg_user_id "read" 1 "test_taBle"] } {
    append html "<li>Group test passed."
} else {
    append html "<li><font color=red>Group test failed.</font>"
}

# group revocation
set permission_id [db_string admin_acceptance_gp_permission_id2_select "select ad_general_permissions.group_permission_id($employee_group_id,'read',1,'TesT_TABLE')
                                               from dual"]
db_dml admin_acceptance_test_gp_permission_revoke2 "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $reg_user_id "read" 1 "TeST_TABLE"] } {
    append html "<li>Group revocation test passed."
} else {
    append html "<li><font color=red>Group revocation test failed. $permission_id</font>"
}

# test roles
set roleexists [db_string admin_acceptance_gp_role_count_select "select count(*) from user_group_roles
                                            where group_id = $employee_group_id
                                            and role = 'gptestrole'"]

if { $roleexists == 0 } {
    db_dml group_insert "insert into user_group_roles(group_id, role, creation_date, creation_user, creation_ip_address)
                   values($employee_group_id, 'gptestrole', sysdate, $system_user_id, '10.0.0.0')"
}

db_exec_plsql admin_acceptance_tests_gp_permission_grant_test "begin :1 := ad_general_permissions.grant_permission_to_role($employee_group_id, 'gptestrole', 'read', 1, 'test_TAble'); end;"

append html "<li>Created group/role read permission record."

# verifies that it doesn't accidentally give the wrong user read permission
if { ![ad_user_has_row_permission_p $reg_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role test one passed."
} else {
    append html "<li><font color=red>Group/role test one failed.</font>"
}

# admin default for system user -- system has administrator role so
# should be able to read
if { [ad_user_has_row_permission_p $system_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role test two passed (tests admin default)."
} else {
    append html "<li><font color=red>Group/role test two failed (tests admin default).</font>"
}

db_dml admin_acceptance_test_gp_role_insert_info_user_group_map "insert into user_group_map(group_id, user_id, role, registration_date, mapping_user, mapping_ip_address)
               values($employee_group_id, $reg_user_id, 'gptestrole', sysdate, $system_user_id, '10.0.0.0')"

# now we insert reg user, make sure it's still okaay
if { [ad_user_has_row_permission_p $reg_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role test three passed."
} else {
    append html "<li><font color=red>Group/role test three failed.</font>"
}

# revoke permission
set permission_id [db_string permission_id3_select "select ad_general_permissions.group_role_permission_id($employee_group_id,'gptestrole','read',1,'teSt_taBle') from dual"]

db_dml permission_revoke3 "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $reg_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role revocation test passed."
} else {
    append html "<li><font color=red>Group/role revocation test failed.</font>"
}

# now, the regular users
db_exec_plsql admin_acceptance_gp_reg_user_test_exec_plsql "begin :1 := ad_general_permissions.grant_permission_to_reg_users('read',1,'teST_tabLE'); end;"

append html "<li>Granted read to all registered users."

if { [ad_user_has_row_permission_p $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>Registered user test passed."
} else {
    append html "<li><font color=red>Registered user test failed.</font>"
}

# now, revoke again (do we see a pattern here?)
set permission_id [db_string permission_id4_select "select ad_general_permissions.reg_users_permission_id('read',1,'teST_table') from dual"]

db_dml admin_acceptance_gp_permission_revoke4 "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>Registered user revocation test passed."
} else {
    append html "<li><font color=red>Registered revocation user test failed.</font>"
}

# now, all users
db_exec_plsql admin_acceptance_tests_all_user_test "begin :1 := ad_general_permissions.grant_permission_to_all_users('read',1,'teST_tabLE'); end;"

append html "<li>Granted read to all users."

if { [ad_user_has_row_permission_p $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>All user test one passed."
} else {
    append html "<li><font color=red>All user test one failed.</font>"
}

if { [ad_user_has_row_permission_p 0 "read" 1 "teST_TaBLE"] } {
    append html "<li>All user test two passed."
} else {
    append html "<li><font color=red>All user test two failed.</font>"
}

# now, revoke
set permission_id [db_string permission_id5_select "select ad_general_permissions.all_users_permission_id('read',1,'teST_taBLE') from dual"]

db_dml admin_acceptance_tests_gp_permisson_revoke5 "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>Revoking all user test one passed."
} else {
    append html "<li><font color=red>Revoking all user test one failed.</font>"
}

if { ![ad_user_has_row_permission_p 0 "read" 1 "teST_TaBLE"] } {
    append html "<li>Revoking all user test two passed."
} else {
    append html "<li><font color=red>Revocating all user test two failed.</font>"
}

# clean up; technically we should put the entire test
# in one transaction, but that seems painful to accept.
db_transaction {
db_dml admin_acceptance_tests_gp_test_table_delete "delete from general_permissions
               where on_which_table = 'test_table'"
db_dml admin_acceptance_tests_gp_testrole_delete "delete from user_group_roles
               where group_id = $employee_group_id
               and role = 'gptestrole'"
db_dml admin_acceptance_tests_gp_testrole2_delete "delete from user_group_map
               where role = 'gptestrole'"
db_dml admin_acceptance_tests_user_delete "delete from user_group_map
               where user_id = $reg_user_id
               and group_id = $employee_group_id"
}

append html "
</ul>Cleanup complete.
[ad_footer]
"

doc_return  200 text/html $html

