# $Id: member-add.tcl,v 3.0.4.1 2000/04/28 15:10:57 carsten Exp $
# File:    /groups/admin/group/member-add.tcl
# Date:    mid-1998
# Contact: tarik@arsdigita.com, teadams@arsdigita.com
# Purpose: display list of user groups for which user has group administration privileges
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_form_variables 0

# maybe role 

set user_id [ad_get_user_id]

set group_name [ns_set get $group_vars_set group_name]
set group_admin_url [ns_set get $group_vars_set group_admin_url]

# we will want to record who was logged in when this person was added
# so let's force admin to register

if {$user_id == 0} {
    ad_returnredirect "/register.tcl?return_url=[ad_urlencode "$group_admin_url/member-add.tcl?[export_url_vars role]"]"
    return
}

if { ![info exists role] } {
    set role ""
}

set db [ns_db gethandle]


if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


append html "
[ad_scope_admin_header "Add Member" $db]
[ad_scope_admin_page_title "Add Member" $db]
[ad_scope_admin_context_bar "Add Member"]
<hr>

Locate your new member by 

<form method=get action=\"/user-search.tcl\">
[export_form_vars role]
<input type=hidden name=target value=\"$group_admin_url/member-add-2.tcl\">
"

if { ![empty_string_p $role] } {
    append html "
    <input type=hidden name=passthrough value=\"role\">
    "
}

append html "
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

[ad_scope_admin_footer]
"

ns_return 200 text/html $html