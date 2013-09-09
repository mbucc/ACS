# /groups/group/spam-index.tcl
ad_page_contract {
    @cvs-id spam-index.tcl,v 3.4.2.5 2000/09/22 01:38:15 kevin Exp
} {
}

set group_name [ns_set get $group_vars_set group_name]
set group_id [ns_set get $group_vars_set group_id]

set user_id [ad_verify_and_get_user_id]

ad_scope_authorize $scope all group_member none

set counter [db_string get_email_pref_count "
select count(*)
from group_member_email_preferences
where group_id = :group_id
and user_id = :user_id "]

if { $counter == 0 } {
    set dont_spam_me_p f
} else {
    set dont_spam_me_p [db_string get_dont_spam_pref "
    select dont_spam_me_p 
    from group_member_email_preferences
    where group_id = :group_id
    and user_id = :user_id "] 
}



set page_html "
[ad_scope_header "Email"]
[ad_scope_page_title "Email"]
[ad_scope_context_bar_ws_or_index [list index $group_name] Email]
<hr>
"


set group_roles_list [db_list get_roles "select distinct role 
from user_group_map
where group_id = :group_id"] 

db_with_handle db {
append html "

<b>Send Email To</b>
<ul>

<form method=post action=spam>
[ad_db_select_widget -size 4 -multiple 1 -default "all" -option_list {{{all} {All }}}  $db "select distinct role , role
from user_group_map
where group_id = $group_id
          " sendto]
<br>

<input type=submit value=\"Send Email\">

</form>

</ul>
<p>

<li>Email Preference[ad_space 1]
<font size=-1>
[ad_choice_bar [list "Receive Group Emails" "Don't Spam Me" ]\
	       [list "edit-preference?dont_spam_me_p=f" "edit-preference?dont_spam_me_p=t"]\
	       [list "f" "t"]  $dont_spam_me_p]
</font>
"
}   
set history_count  [db_string get_gs_history_count "select count(*)
from group_spam_history 
where group_id = :group_id
and sender_id = :user_id"]

if { $history_count > 0 } {

    db_1row get_recent_history_events "select 
    max(creation_date) as max_creation_date , 
    min(creation_date) as min_creation_date 
    from group_spam_history 
    where group_id = :group_id
    and sender_id = :user_id"
   
    
    append html "
    <p>
    <li>Email History </b> [ad_space 1]
    <a href=\"spam-history?[export_url_vars user_id]\">$history_count emails between [util_AnsiDatetoPrettyDate $min_creation_date] and [util_AnsiDatetoPrettyDate $max_creation_date]</a>
    <p>
    "
}

doc_return  200 text/html  "
$page_html
<blockquote>
$html
</blockquote>

[ad_scope_footer]
"











