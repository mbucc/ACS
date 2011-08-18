# $Id: spam-index.tcl,v 3.0.4.1 2000/05/09 15:40:44 carsten Exp $
# File: /groups/group/spam-index.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: this is the group spam main page
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id $db]

ad_scope_authorize $db $scope all group_member none

set counter [database_to_tcl_string $db "
select count(*)
from group_member_email_preferences
where group_id = $group_id
and user_id = $user_id "]

if { $counter == 0 } {
    set dont_spam_me_p f
} else {
    set dont_spam_me_p [database_to_tcl_string $db "
    select dont_spam_me_p 
    from group_member_email_preferences
    where group_id = $group_id
    and user_id = $user_id "] 
}

ReturnHeaders 

ns_write "
[ad_scope_header "Email" $db]
[ad_scope_page_title "Email" $db]
[ad_scope_context_bar_ws_or_index [list index.tcl $group_name] Email]
<hr>
"

append html "

<b>Send Email To</b>
<ul>
    <li><a href=\"spam.tcl?sendto=members\">Group Members</a>
    <li><a href=\"spam.tcl?sendto=administrators\">Group Administrators</a>
</ul>

<p>
<li>Email Preference[ad_space 1]
<font size=-1>
[ad_choice_bar [list "Receive Group Emails" "Don't Spam Me" ]\
	       [list "edit-preference.tcl?dont_spam_me_p=f" "edit-preference.tcl?dont_spam_me_p=t"]\
	       [list "f" "t"] $dont_spam_me_p]
</font>
"
set history_count  [database_to_tcl_string $db "select count(*)
from group_spam_history 
where group_id = $group_id
and sender_id = $user_id"]

if { $history_count > 0 } {

    set selection [ns_db 1row $db "select 
    max(creation_date) as max_creation_date , 
    min(creation_date) as min_creation_date 
    from group_spam_history 
    where group_id = $group_id
    and sender_id = $user_id"]
    
    set_variables_after_query
    
    append html "
    <p>
    <li>Email History </b> [ad_space 1]
    <a href=\"spam-history.tcl?[export_url_vars user_id]\">$history_count emails between [util_AnsiDatetoPrettyDate $min_creation_date] and [util_AnsiDatetoPrettyDate $max_creation_date]</a>
    <p>
    "
}

ns_write "

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"











