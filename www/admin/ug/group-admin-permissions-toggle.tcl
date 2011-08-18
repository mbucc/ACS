# $Id: group-admin-permissions-toggle.tcl,v 3.0.4.1 2000/04/28 15:09:26 carsten Exp $
# Form variables: 
# group_id       the id of the group


set_form_variables

set db [ns_db gethandle]

ns_db dml $db "update user_groups set group_admin_permissions_p = logical_negation(group_admin_permissions_p) where group_id = $group_id"


ad_returnredirect "group.tcl?[export_url_vars group_id]"
