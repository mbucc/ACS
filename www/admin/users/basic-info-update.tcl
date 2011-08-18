# $Id: basic-info-update.tcl,v 3.1 2000/03/09 00:01:33 scott Exp $
set_the_usual_form_variables

# user_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select first_names, 
       last_name, 
       email, 
       url,
       screen_name
from users 
where user_id=$user_id"]

set_variables_after_query

ns_db releasehandle $db

append whole_page "
[ad_admin_header "Update Basic Information"]

<h2>Update Basic Information</h2>

for $first_names $last_name

<hr>

<form method=POST action=\"basic-info-update-2.tcl\">
[export_form_vars user_id]

<table>
<tr>
 <th>Name:<td><input type=text name=first_names size=20 value=\"$first_names\"> <input type=text name=last_name size=25 value=\"$last_name\">
</tr>
<tr>
 <th>email address:<td><input type=text name=email size=30 value=\"$email\">
</tr>
<tr>
 <th>Personal URL:<td><input type=text name=url size=50 value=\"$url\">
</tr>
<tr>
 <th>Screen name:<td><input type=text name=screen_name size=15 value=\"$screen_name\">
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
