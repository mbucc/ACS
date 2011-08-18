# $Id: role-edit-2.tcl,v 3.1.2.1 2000/04/28 15:10:59 carsten Exp $
# File:    /groups/admin/group/role-edit-2.tcl
# Date:    mid-1998
# Contact: tarik@arsdigita.com
# Purpose: edit the role for the user
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_form_variables

# user_id, exisiting_role and/or new_role

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


if { [info exists new_role] && ![empty_string_p $new_role] } {
    set role $new_role
} else {
    set role $existing_role
}

if { ![info exists role] || [empty_string_p $role] } {
    ad_return_complaint 1 "<li>Please pick a role." 
    return
}


ns_db dml $db "
     update user_group_map
        set role = '[DoubleApos $role]'
      where user_id = $user_id
        and group_id = $group_id
        and role = '[DoubleApos $existing_role]'"

ad_returnredirect members.tcl
