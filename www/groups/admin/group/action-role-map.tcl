# $Id: action-role-map.tcl,v 3.0.4.1 2000/04/28 15:10:57 carsten Exp $
# File:     /groups/admin/group/action-role-map.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  allow users with the role $role to do action $action
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# role, action

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id $db] != 1 || [database_to_tcl_string $db "select group_admin_permissions_p from user_groups where group_id=$group_id"] == "f" } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

ns_db dml $db "
insert into user_group_action_role_map (group_id, role, action, creation_user, creation_ip_address)
select $group_id, '$QQrole', '$QQaction', [ad_get_user_id], '[DoubleApos [ns_conn peeraddr]]' 
from dual 
where not exists (select role from user_group_action_role_map where group_id = $group_id and role = '$QQrole' and action = '$QQaction')"

ad_returnredirect members.tcl

