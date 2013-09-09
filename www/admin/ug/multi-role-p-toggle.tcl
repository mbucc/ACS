ad_page_contract {
    @param group_id       the id of the group
    
    @cvs-id multi-role-p-toggle.tcl,v 3.2.2.5 2000/07/24 18:38:28 ryanlee Exp
} {
    group_id:notnull,naturalnum
}

db_dml update_ug_multirole_p "update user_groups set multi_role_p = logical_negation(multi_role_p) where group_id = :group_id"
db_release_unused_handles

ad_returnredirect "group?[export_url_vars group_id]"



