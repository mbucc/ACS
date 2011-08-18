# $Id: membership-refuse.tcl,v 3.0 2000/02/06 03:46:04 ron Exp $
# File:     /groups/admin/group/membership-refuse.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  deny membership to user who applied for it (used only for groups,
#           which heave new members policy set to wait)
#
# Note: group_id and group_vars_set are already set up in the environment y the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# user_id

set group_name [ns_set get $group_vars_set group_name]
set group_admin_url [ns_set get $group_vars_set group_admin_url]
set db [ns_db gethandle]

set name [database_to_tcl_string  $db "
select first_names || ' ' || last_name from users where user_id = $user_id"]
 
ns_return 200 text/html "
[ad_scope_admin_header "Really refuse $name?" $db]
[ad_scope_admin_page_title "Really refuse $name?" $db]
[ad_scope_admin_context_bar "Refuse $name"]
<hr>

<center>
<table>
<tr><td>
<form method=get action=members.tcl>
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"membership-refuse-2.tcl\">
[export_form_vars user_id]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
[ad_scope_admin_footer]
"
