ad_page_contract {
    @param group_id The ID of the group being worked on
    @param role Role of the new member
    @param return_url The URL to return to

    @cvs-id member-add.tcl,v 3.2.6.9 2000/09/22 01:36:16 kevin Exp
} {
    group_id:naturalnum,notnull
    {role ""}
    {return_url ""}
}

# 3.4 upgrade complete by teadams on July 9, 2000

set user_id [ad_get_user_id]

# we will want to record who was logged in when this person was added
# so let's force admin to register

ad_maybe_redirect_for_registration

append return_html "[ad_admin_header -focus search.email "Add Member"]

<h2>Add Member</h2>

"

set group_name [db_string user_group_name_from_id "select group_name from user_groups where group_id = :group_id"]

set target /admin/ug/member-add-2
set passthrough {group_id role return_url}

append return_html "

to <a href=\"group?group_id=$group_id\">$group_name</a>

<hr>

Locate your new member by 

<form method=get action=\"/admin/users/search\" name=search>
[export_form_vars group_id role return_url target passthrough]
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

[ad_admin_footer]
"

doc_return  200 text/html $return_html








