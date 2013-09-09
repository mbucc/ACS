# www/portals/admin/add-manager-2.tcl

ad_page_contract {
    insert the user as a portal manager

    @author aure@arsdigita.com
    @author dh@arsdigita.com
    @creation-date 10/8/1999
    @param group_id naturalnum,optional
    @param user_id_from_search
    @param first_names_from_search
    @param last_name_from_search
    @param email_from_search
    @cvs-id add-manager-2.tcl,v 3.4.2.6 2000/07/21 04:03:26 ron Exp
} {
    {group_id:naturalnum,optional}
    user_id_from_search
    first_names_from_search
    last_name_from_search
    email_from_search
}

if {![info exists group_id]} {
    ad_returnredirect index
    return
}

set user_id [ad_verify_and_get_user_id]
portal_check_administrator_maybe_redirect $user_id

# check if this person is already an administrator of this group
set check_result [db_string portal_admin_add_manager_check_user "
    select decode ( ad_user_has_role_p ( :user_id_from_search, :group_id, 'administrator' ), 'f', 0, 1 ) 
    from   dual"]

if { $check_result == 0 } {
    set peeraddr [ns_conn peeraddr]
    db_dml portal_admin_add_manager_insert_admin "
        insert into user_group_map
        (user_id, group_id, role, mapping_user, mapping_ip_address)
        values
        (:user_id_from_search, :group_id, 'administrator',:user_id,:peeraddr) "
}

db_release_unused_handles
ad_returnredirect index




