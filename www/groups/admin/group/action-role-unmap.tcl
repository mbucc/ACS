ad_page_contract {

    Forbid users with the role $role to do action $action.

    @param role The role to unmap from
    @param action The action to unmap

    @author Tracy Adams [teadams@arsdigita.com]
    @author tarik@arsdigita.com
    @cvs-id action-role-unmap.tcl,v 3.1.6.5 2000/07/28 23:10:16 pihman Exp

} {
    role:notnull
    action:notnull
}

set user_id [ad_verify_and_get_user_id]
set ip_addr [ns_conn peeraddr]

if { [ad_user_group_authorized_admin $user_id $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set group_admin_permissions_p [db_string group_admin_p \
	"select group_admin_permissions_p from user_groups where group_id=:group_id"]
if { [string compare $group_admin_permissions_p "f"] == 0 } {
    db_release_unused_handles
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


db_dml role_delete {
    delete from 
    user_group_action_role_map
    where group_id = :group_id 
    and role = :role and action = :action
}
db_release_unused_handles

ad_returnredirect members

