# www/admin/portals/add-manager-2.tcl

ad_page_contract {
    adds a person to the list of super administrators 

    @param user_id_from_search user id from the search page
    @param first_names_from_search user first name from the search page
    @param last_names_from_search user last name from the search page
    @param email_from_search user e-mail from the search page

    @author aure@arsdigita.com 
    @author dh@arsdigita.com
    @creation-date 10/8/1999
    @cvs-id add-manager-2.tcl,v 3.3.2.9 2000/07/21 22:20:35 david Exp

} {
    {user_id_from_search:integer}
    first_names_from_search
    last_name_from_search
    email_from_search
}

# get group_id for super users
set group_id [db_string group_id_for_super_admins "select group_id 
    from user_groups
    where group_name = 'Super Administrators'
    and group_type = 'portal_group'"]

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration 

# check if this person is already an administrator of this group
set check_result [db_string already_admin_p "select decode ( ad_user_has_role_p ( :user_id_from_search, :group_id, 'administrator' ), 'f', 0, 1 ) from dual"]

set bind_vars_peeraddr '[ns_conn peeraddr]'

if { $check_result == 0 } {
    db_dml user_group_mapping_insert "
        insert into user_group_map
        (user_id, group_id, role, mapping_user, mapping_ip_address)
        values
        (:user_id_from_search, :group_id, 'administrator', :user_id, :bind_vars_peeraddr) "
}

db_release_unused_handles

ad_returnredirect index.tcl
















