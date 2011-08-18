# $Id: admin-authorize-user-new.tcl,v 3.0 2000/02/06 03:32:19 ron Exp $
set_form_variables

# topic

ReturnHeaders 

ns_write  "[bboard_header "New User"]
<h2>New User</h2>
for <a href=\"admin-authorized-users.tcl?topic=[ns_urlencode $topic]\">$topic</a>.
<hr><p>
<form action=\"/user-search.tcl\" method=get>
<input type=hidden name=target value=\"/bboard/admin-authorize-user-new-2.tcl\">
<input type=hidden name=passthrough value=\"topic\">
<input type=hidden name=custom_title value=\"Choose a New Authorized Member for $topic\">
<input type=hidden name=topic value=\"$topic\">
Search for a [ad_system_name] user to add $topic by 
<p>
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>
 <input type=submit value=\"Search for user\">
<p>
[bboard_footer]"
