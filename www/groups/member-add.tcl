ad_page_contract {
    @param group_id the ID of the group
    @param role:optional the role of the user
    @param return_url:optional the url to send the user back to
    
    @cvs-id member-add.tcl,v 3.2.6.5 2000/09/22 01:38:08 kevin Exp
} {
    group_id:notnull,naturalnum
    role:optional
    return_url:optional
}
set user_id [ad_get_user_id]

# we will want to record who was logged in when this person was added
# so let's force admin to register

if {$user_id == 0} {
   ad_returnredirect "/register?return_url=[ns_urlencode "/admin/ug/member-add?[export_url_vars group_id role return_url]"]"
    return
}





set page_html "[ad_header "Add Member"]

<h2>Add Member</h2>

"

set group_name [db_string get_group_name "select group_name from user_groups where group_id = :group_id"]

append page_html "to <a href=\"group?group_id=$group_id\">$group_name</a>

<hr>

Locate your new member by 

<form method=get action=\"/user-search\">
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

doc_return  200 text/html $page_html



