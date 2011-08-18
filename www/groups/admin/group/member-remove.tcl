# $Id: member-remove.tcl,v 3.1.2.1 2000/04/11 11:57:40 carsten Exp $
# File:     /groups/admin/group/member-remove.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  remove member from the user group
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# user_id

set group_name [ns_set get $group_vars_set group_name]
set group_admin_url [ns_set get $group_vars_set group_admin_url]

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

if { ![ad_user_group_member $db $group_id $user_id] } {
    ad_return_error "Not a Member" "The user you are trying to remove is not a member of this group."
    return
}

set name [database_to_tcl_string_or_null $db "
select first_names || ' ' || last_name
from users, user_groups 
where users.user_id = $user_id
and user_groups.group_id = $group_id
and ad_group_member_p ( $user_id, $group_id ) = 't'"]

ReturnHeaders 

ns_write "
[ad_scope_admin_header "Really remove $name?" $db]
[ad_scope_admin_page_title "Really remove $name?" $db]
[ad_scope_admin_context_bar "Remove $name"]
<hr>

<center>
<table>
<tr><td>
<form method=get action=members.tcl>
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"member-remove-2.tcl\">
[export_form_vars user_id]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
</center>
[ad_scope_admin_footer]
"
