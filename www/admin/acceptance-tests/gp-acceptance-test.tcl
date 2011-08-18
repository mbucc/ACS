# /admin/acceptance/tests/gp-acceptance-test.tcl
#
# automated general permissions acceptance test (tests pl/sql procs
# and data model)
#
# by richardl@arsdigita.com, created 2000 March 16
#
# $Id: gp-acceptance-test.tcl,v 1.1.2.1 2000/03/17 15:41:48 richardl Exp $

# requires:
# o existence of system user
# o existence of site-wide admin group
# o existence of non-system user

# all table names are inconsistently capitalized to test the to_lower stuff in PL/SQL
set html "
[ad_header "General Permissions acceptance test"]
<h2>General Permissions acceptance test</h2>
Running...
<ul>
"
set db [ns_db gethandle]
set system_user_id [database_to_tcl_string $db "select user_id from users where email = 'system'"]
set reg_user_id [database_to_tcl_string $db "select max(user_id) from users where email <> 'system'"]

# test read permissions for system
ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_user($system_user_id,'read',1,'TEST_TabLE'); end;"
append html "<li>Created user read permission record."

if { [ad_user_has_row_permission_p $db $system_user_id "read" 1 "TEST_TABLE"] } {
    append html "<li>User test passed."
} else {
    append html "<li><font color=red>User test failed.</font>"
}

# test revoking permission
set permission_id [database_to_tcl_string $db "select ad_general_permissions.user_permission_id($system_user_id,'read',1,'TesT_TABLE')
                                               from dual"]
ns_db dml $db "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $db $system_user_id "read" 1 "TEST_TABLE"] } {
    append html "<li>User revocation test passed."
} else {
    append html "<li><font color=red>User revocation test failed.</font>"
}

# test group stuff now
set sitewide_group_id [database_to_tcl_string $db "select group_id from user_groups
                                                   where group_name = 'Site-Wide Administration'"]

ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_group($sitewide_group_id,'read',1,'TEST_tabLE'); end;"

append html "<li>Created group read permission record."

if { [ad_user_has_row_permission_p $db $system_user_id "read" 1 "test_taBle"] } {
    append html "<li>Group test passed."
} else {
    append html "<li><font color=red>Group test failed.</font>"
}

# group revocation
set permission_id [database_to_tcl_string $db "select ad_general_permissions.group_permission_id($sitewide_group_id,'read',1,'TesT_TABLE')
                                               from dual"]
ns_db dml $db "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $db $system_user_id "read" 1 "TeST_TABLE"] } {
    append html "<li>Group revocation test passed."
} else {
    append html "<li><font color=red>Group revocation test failed. $permission_id</font>"
}

# test roles
set roleexists [database_to_tcl_string $db "select count(*) from user_group_roles
                                            where group_id = $sitewide_group_id
                                            and role = 'gptestrole'"]

if { $roleexists == 0 } {
    ns_db dml $db "insert into user_group_roles(group_id, role, creation_date, creation_user, creation_ip_address)
                   values($sitewide_group_id, 'gptestrole', sysdate, $system_user_id, '10.0.0.0')"
}

ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_role($sitewide_group_id, 'gptestrole', 'read', 1, 'test_TAble'); end;"

append html "<li>Created group/role read permission record."

# verifies that it doesn't accidentally give the wrong user read permission
if { ![ad_user_has_row_permission_p $db $reg_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role test one passed."
} else {
    append html "<li><font color=red>Group/role test one failed.</font>"
}

# admin default for system user -- system has administrator role so
# should be able to read
if { [ad_user_has_row_permission_p $db $system_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role test two passed (tests admin default)."
} else {
    append html "<li><font color=red>Group/role test two failed (tests admin default).</font>"
}

ns_db dml $db "insert into user_group_map(group_id, user_id, role, registration_date, mapping_user, mapping_ip_address)
               values($sitewide_group_id, $reg_user_id, 'gptestrole', sysdate, $system_user_id, '10.0.0.0')"

# now we insert reg user, make sure it's still okaay
if { [ad_user_has_row_permission_p $db $reg_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role test three passed."
} else {
    append html "<li><font color=red>Group/role test three failed.</font>"
}

# revoke permission
set permission_id [database_to_tcl_string $db "select ad_general_permissions.group_role_permission_id($sitewide_group_id,'gptestrole','read',1,'teSt_taBle') from dual"]

ns_db dml $db "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $db $reg_user_id "read" 1 "TESt_table"] } {
    append html "<li>Group/role revocation test passed."
} else {
    append html "<li><font color=red>Group/role revocation test failed.</font>"
}

# now, the regular users
ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_reg_users('read',1,'teST_tabLE'); end;"

append html "<li>Granted read to all registered users."

if { [ad_user_has_row_permission_p $db $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>Registered user test passed."
} else {
    append html "<li><font color=red>Registered user test failed.</font>"
}

# now, revoke again (do we see a pattern here?)
set permission_id [database_to_tcl_string $db "select ad_general_permissions.reg_users_permission_id('read',1,'teST_table') from dual"]

ns_db dml $db "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $db $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>Registered user revocation test passed."
} else {
    append html "<li><font color=red>Registered revocation user test failed.</font>"
}

# now, all users
ns_ora exec_plsql $db "begin :1 := ad_general_permissions.grant_permission_to_all_users('read',1,'teST_tabLE'); end;"

append html "<li>Granted read to all users."

if { [ad_user_has_row_permission_p $db $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>All user test one passed."
} else {
    append html "<li><font color=red>All user test one failed.</font>"
}

if { [ad_user_has_row_permission_p $db 0 "read" 1 "teST_TaBLE"] } {
    append html "<li>All user test two passed."
} else {
    append html "<li><font color=red>All user test two failed.</font>"
}

# now, revoke
set permission_id [database_to_tcl_string $db "select ad_general_permissions.all_users_permission_id('read',1,'teST_taBLE') from dual"]

ns_db dml $db "begin ad_general_permissions.revoke_permission($permission_id); end;"

if { ![ad_user_has_row_permission_p $db $reg_user_id "read" 1 "teST_TaBLE"] } {
    append html "<li>Revoking all user test one passed."
} else {
    append html "<li><font color=red>Revoking all user test one failed.</font>"
}

if { ![ad_user_has_row_permission_p $db 0 "read" 1 "teST_TaBLE"] } {
    append html "<li>Revoking all user test two passed."
} else {
    append html "<li><font color=red>Revocating all user test two failed.</font>"
}


# clean up; technically we should put the entire test
# in one transaction, but that seems painful to accept.
ns_db dml $db "begin transaction"
ns_db dml $db "delete from general_permissions
               where on_which_table = 'test_table'"
ns_db dml $db "delete from user_group_roles
               where group_id = $sitewide_group_id
               and role = 'gptestrole'"
ns_db dml $db "delete from user_group_map
               where role = 'gptestrole'"
ns_db dml $db "end transaction"

append html "
</ul>Cleanup complete.
[ad_footer]"



ns_db releasehandle $db
ns_return 200 text/html $html