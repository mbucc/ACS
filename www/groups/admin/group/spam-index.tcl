# $Id: spam-index.tcl,v 3.0 2000/02/06 03:46:12 ron Exp $
# File:     /groups/admin/group/spam-index.tcl
# Date:     Mon Jan 17 13:39:51 EST 2000
# Contact:  ahmeds@mit.edu
# Purpose:  group spam administration page
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

set helper_args [list "spam-policy-update-form.tcl" "Group Spam Policy"]

ReturnHeaders 

ns_write "
[ad_scope_admin_header "Spam Administration" $db]
[ad_scope_admin_page_title "Spam Administration" $db]
[ad_scope_admin_context_bar "Spam Admin"]
<hr>
[help_upper_right_menu $helper_args]
"

set group_public_url [ns_set get $group_vars_set group_public_url]
append html "
<li><a href=/doc/group-spam.html>Documentation</a></br>
<li><a href=$group_public_url/spam-index.tcl>User pages</a>
"

append html "

<p>

<b>Send Spam to </b>
<ul>  
    <li><a href=\"spam.tcl?sendto=members\">Group Members</a>
    <li><a href=\"spam.tcl?sendto=administrators\">Group Administrators</a>
</ul>
"
set selection [ns_db select $db "select gsh.*, first_names, last_name 
from group_spam_history gsh, users u
where gsh.group_id = $group_id
and gsh.sender_id = u.user_id
and gsh.approved_p is null
order by gsh.creation_date "]

set counter 0 

set approval_html "
<b> Spams Awaiting Approval </b>
<ul>
"

while { [ns_db getrow $db $selection ]} {
    set_variables_after_query

    incr counter

    append approval_html "
    <li><a href=spam-item.tcl?[export_url_vars spam_id]>[util_AnsiDatetoPrettyDate $creation_date]</a> by  $first_names $last_name
    "
}

if {$counter > 0} {
    append approval_html "</ul>"
    append html $approval_html
}


set history_count  [database_to_tcl_string $db "select count(*)
from group_spam_history 
where group_id = $group_id"]

if { $history_count > 0 } {
    set selection [ns_db 1row $db "select 
    max(creation_date) as max_creation_date , 
    min(creation_date) as min_creation_date 
    from group_spam_history 
    where group_id = $group_id"]
    
    set_variables_after_query
    
    append html "
    <b> Spam History </b> [ad_space 1]
    <a href=\"spam-history.tcl?[export_url_vars group_id]\">$history_count emails between [util_AnsiDatetoPrettyDate $min_creation_date] and [util_AnsiDatetoPrettyDate $max_creation_date]</a>
    <p>
    "
}

ns_write "
<blockquote>
$html
</blockquote>

[ad_scope_admin_footer] 
"
