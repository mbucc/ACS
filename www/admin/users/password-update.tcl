# $Id: password-update.tcl,v 3.1 2000/03/09 00:01:35 scott Exp $
set_the_usual_form_variables

# user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name, email, url from users where user_id=$user_id"]
set_variables_after_query

ns_db releasehandle $db

append whole_page "
[ad_admin_header "Update Password"]

<h2>Update Password</h2>

for $first_names $last_name in [ad_site_home_link]

<hr>

<form method=POST action=\"password-update-2.tcl\">

<table>
[export_form_vars user_id first_names last_name]
<tr>
 <th>New Password:<td><input type=password name=password_1 size=15>
</tr>
<tr>
 <th>Confirm:<td><input type=password name=password_2 size=15>
</tr>
</table>

<br>
<br>
<center>
<input type=submit value=\"Update\">
</center>

[ad_admin_footer]
"
ns_return 200 text/html $whole_page
