# /groups/admin/group/spam-policy-update-form.tcl
ad_page_contract {

 Purpose:  group spam policy update form

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
@cvs-id spam-policy-update-form.tcl,v 3.3.2.5 2000/09/22 01:38:13 kevin Exp
} {
}

set group_name [ns_set get $group_vars_set group_name]



if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_1row get_spam_policy_from_ug "
select spam_policy
from user_groups 
where group_id = :group_id"

set page_html "
[ad_scope_admin_header "Group Spam Policy"]
[ad_scope_admin_page_title "Group Spam Policy"]
[ad_scope_admin_context_bar [list "spam-index" "Spam Admin"] "Spam Policy"]
<hr>

"

append html "
<form action=spam-policy-update method=post>

<b>Group Spam Policy </b> [ad_space 1]
<select name=spam_policy>
[ad_generic_optionlist { open wait closed }  { open wait closed } $spam_policy]
</select>
<input type=submit name=submit value=\"Update\">
</form>
<p>
"

doc_return  200 text/html "$page_html
<blockquote>
$html
</blockquote>

[ad_scope_admin_footer] 
"
