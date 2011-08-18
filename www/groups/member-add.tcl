# $Id: member-add.tcl,v 3.0.4.1 2000/04/28 15:10:56 carsten Exp $
set_the_usual_form_variables

# group_id, maybe role,return_url

set user_id [ad_get_user_id]

# we will want to record who was logged in when this person was added
# so let's force admin to register

if {$user_id == 0} {
   ad_returnredirect "/register.tcl?return_url=[ns_urlencode "/admin/ug/member-add.tcl?[export_url_vars group_id role return_url]"]"
    return
}

set db [ns_db gethandle]

ReturnHeaders 

ns_write "[ad_header "Add Member"]

<h2>Add Member</h2>

"

set group_name [database_to_tcl_string $db "select group_name from user_groups where group_id = $group_id"]

ns_write "to <a href=\"group.tcl?group_id=$group_id\">$group_name</a>

<hr>

Locate your new member by 

<form method=get action=\"/user-search.tcl\">
[export_entire_form]
<input type=hidden name=target value=\"/groups/member-add-2.tcl\">
<input type=hidden name=passthrough value=\"group_id role return_url\">
<table border=0>
<tr><td>Email address:<td><input type=text name=email size=40></tr>
<tr><td colspan=2>or by</tr>
<tr><td>Last name:<td><input type=text name=last_name size=40></tr>
</table>

<p>

<center>
<input type=submit value=\"Search\">
</center>
</form>

[ad_footer]
"
