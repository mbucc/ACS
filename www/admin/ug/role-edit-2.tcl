# $Id: role-edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:34 carsten Exp $
set_form_variables

# user_id, group_id, exisiting_role and/or new_role

if { [info exists new_role] && ![empty_string_p $new_role] } {
    set role $new_role
} else {
    set role $existing_role
}

if { ![info exists role] || [empty_string_p $role] } {
    ad_return_complaint 1 "<li>Please pick a role." 
    return
}

set db [ns_db gethandle]

ns_db dml $db "update user_group_map set role='[DoubleApos $role]'
where user_id = $user_id and group_id = $group_id"

ad_returnredirect "group.tcl?[export_url_vars group_id]"