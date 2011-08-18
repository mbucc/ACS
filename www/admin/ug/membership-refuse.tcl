# $Id: membership-refuse.tcl,v 3.0 2000/02/06 03:29:41 ron Exp $
set_the_usual_form_variables

# group_id, user_id

set db [ns_db gethandle]

set name [database_to_tcl_string  $db "select first_names || ' ' || last_name from users where user_id = $user_id"]

set group_name [database_to_tcl_string  $db "select group_name from user_groups where group_id = $group_id"]


ReturnHeaders 

ns_write "[ad_admin_header "Really refuse $name?"]

<h2> Really refuse $name?</h2>

as a member in <a href=\"group.tcl?[export_url_vars group_id]\">$group_name</a>

<hr>

<center>
<table>
<tr><td>
<form method=get action=\"group.tcl\">
[export_form_vars group_id]
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"membership-refuse-2.tcl\">
[export_form_vars group_id user_id]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
[ad_admin_footer]
"
