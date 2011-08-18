# $Id: password-update.tcl,v 3.0 2000/02/06 03:53:36 ron Exp $
set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set selection [ns_db 1row $db "select first_names, last_name, email, url from users where user_id=$user_id"]
set_variables_after_query

ReturnHeaders 

ns_write "
[ad_header "Update Password"]

<h2>Update Password</h2>

for $first_names $last_name in [ad_site_home_link]

<hr>

<form method=POST action=\"password-update-2.tcl\">

<table>
<tr>
 <th>Current Password:<td><input type=password name=password_old size=15>
</tr>
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

[ad_footer]
"
