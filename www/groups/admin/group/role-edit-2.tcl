# File:    /groups/admin/group/role-edit-2.tcl
ad_page_contract {
    @param user_id the user to change role
    @param existing_role the existing role to change to
    @param new_role a new role to change to

    Edit the role for the user.

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)

    @cvs-id role-edit-2.tcl,v 3.3.2.5 2000/07/26 23:01:40 ryanlee Exp
} {
    user_id:notnull,naturalnum
    existing_role:notnull
    new_role:optional
}


if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

if { [info exists new_role] && ![empty_string_p $new_role] } {
    set role $new_role
} else {
    set role $existing_role
}

if [catch { db_dml update_ug_role_map "
     update user_group_map
        set role = :role
      where user_id = :user_id
        and group_id = :group_id
    " } errmsg] {
    ad_return_error "Database error" "The database is complaining:\n<pre>\n$errmsg\n</pre>\n"
    return
}

db_release_unused_handles

ad_returnredirect members
