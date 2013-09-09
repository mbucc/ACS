# File:     /groups/admin/group/spam-index.tcl
ad_page_contract {
    
 Purpose:  group spam administration page

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
    @cvs-id spam-index.tcl,v 3.4.2.6 2000/09/22 01:38:13 kevin Exp
} {
}

set group_name [ns_set get $group_vars_set group_name]



if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_1row get_spam_policy "
select spam_policy
from user_groups 
where group_id = :group_id"



set helper_args [list "spam-policy-update-form" "Group Spam Policy"]



set page_html "
[ad_scope_admin_header "Spam Administration"]
[ad_scope_admin_page_title "Spam Administration"]
[ad_scope_admin_context_bar "Spam Admin"]
<hr>
[help_upper_right_menu $helper_args]
"

set group_public_url [ns_set get $group_vars_set group_public_url]
append html "
<li><a href=/doc/group-spam>Documentation</a></br>
<li><a href=$group_public_url/spam-index>User pages</a>
"


set group_roles_list [db_list get_roles_from_ugm "select distinct role 
from user_group_map
where group_id = :group_id"] 

append html "

<p>

<b>Send Email To</b>
<ul>

<form method=post action=spam>"
db_with_handle db {
append html [ad_db_select_widget -size 4 -multiple 1 -default "all" -option_list {{{all} {All}}}  $db "select distinct role , role
from user_group_map
where group_id = $group_id
          " sendto]
}

append html "
<br>

<input type=submit value=\"Send Email\">

</form>

</ul>
"
set counter 0 

set approval_html "
<b> Spams Awaiting Approval </b>
<ul>
"

db_foreach get_unsent_spams "select gsh.*, first_names, last_name 
from group_spam_history gsh, users u
where gsh.group_id = :group_id
and gsh.sender_id = u.user_id
and gsh.approved_p is null
order by gsh.creation_date " {



    incr counter

    append approval_html "
    <li><a href=spam-item?[export_url_vars spam_id]>[util_AnsiDatetoPrettyDate $creation_date]</a> by  $first_names $last_name
    "
}

if {$counter > 0} {
    append approval_html "</ul>"
    append html $approval_html
}

set history_count  [db_string get_history_count "select count(*)
from group_spam_history 
where group_id = :group_id"]

if { $history_count > 0 } {
    db_1row get_mr_spam_history "select 
    max(creation_date) as max_creation_date , 
    min(creation_date) as min_creation_date 
    from group_spam_history 
    where group_id = :group_id"
    
    
    
    append html "
    <b> Spam History </b> [ad_space 1]
    <a href=\"spam-history?[export_url_vars group_id]\">$history_count emails between [util_AnsiDatetoPrettyDate $min_creation_date] and [util_AnsiDatetoPrettyDate $max_creation_date]</a>
    <p>
    "
}


doc_return  200 text/html "
$page_html
<blockquote>
$html
</blockquote>

[ad_scope_admin_footer] 
"




