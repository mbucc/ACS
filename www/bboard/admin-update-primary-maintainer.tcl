# $Id: admin-update-primary-maintainer.tcl,v 3.0 2000/02/06 03:33:17 ron Exp $
set_the_usual_form_variables

# topic, topic_id

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}

ReturnHeaders

ns_write "<html>
<head>
<title>Change primary maintainer for $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Change primary maintainer</h2>

for \"$topic\"

<hr>

Current Maintainer:  [database_to_tcl_string $db "select first_names || ' ' || last_name || ' ' || '(' || email || ')' 
from users 
where user_id = $primary_maintainer_id"]

<p>

Search for a new user to be primary administrator of this forum by<br>
<form action=\"/user-search.tcl\" method=POST>
[export_form_vars topic topic_id]
<input type=hidden name=target value=\"/bboard/admin-update-primary-maintainer-2.tcl\">
<input type=hidden name=passthrough value=\"topic_id\">
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
<center>
<input type=submit value=\"Search\">
</center>
</form>

[ad_admin_footer]
"

