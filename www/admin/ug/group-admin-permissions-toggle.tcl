# group-admin-permissions-toggle.tcl,v 3.2.2.2 2000/07/21 20:28:52 ryanlee Exp


ad_page_contract {
 
    @param group_id the id of the group to perform the action on 

    @cvs-id group-admin-permissions-toggle.tcl,v 3.2.2.2 2000/07/21 20:28:52 ryanlee Exp

} {
    group_id:notnull,naturalnum 
}


db_dml update_ga_permissions_p "update user_groups set group_admin_permissions_p = logical_negation(group_admin_permissions_p) where group_id = :group_id"

ad_returnredirect "group?[export_url_vars group_id]"
