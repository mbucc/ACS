# $Id: spam-policy-update-form.tcl,v 3.0 2000/02/06 03:46:15 ron Exp $
# File:     /groups/admin/group/spam-policy-update-form.tcl
# Date:     Mon Jan 17 13:39:51 EST 2000
# Contact:  ahmeds@mit.edu
# Purpose:  group spam policy update form
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


set selection [ns_db 1row $db "
select spam_policy
from user_groups 
where group_id = $group_id"]

set_variables_after_query

ReturnHeaders 

ns_write "
[ad_scope_admin_header "Group Spam Policy" $db]
[ad_scope_admin_page_title "Group Spam Policy" $db]
[ad_scope_admin_context_bar [list "spam-index.tcl" "Spam Admin"] "Spam Policy"]
<hr>

"

append html "
<form action=spam-policy-update.tcl method=post>

<b>Group Spam Policy </b> [ad_space 1]
<select name=spam_policy>
[ad_generic_optionlist { open wait closed }  { open wait closed } $spam_policy]
</select>
<input type=submit name=submit value=\"Update\">
</form>
<p>
"

ns_write "
<blockquote>
$html
</blockquote>

[ad_scope_admin_footer] 
"
