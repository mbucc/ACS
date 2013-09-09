# File:     /groups/admin/group/spam-confirm.tcl
ad_page_contract {
    @param sendto address to send mail to
    @param subject subject of the mail
    @param message the message contents

    @cvs-id spam-confirm.tcl,v 3.7.2.9 2000/09/22 01:38:13 kevin Exp

 Purpose:  this is the group spam confirm page

 Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
} {
    sendto:notnull
    from_address:notnull
    subject:optional
    message:allhtml,notnull
}


set group_name [ns_set get $group_vars_set group_name]

set sendto_string [join $sendto ", "] 



if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}



set page_html  "
[ad_scope_admin_header "Confirm Spamming $sendto_string"]
[ad_scope_admin_page_title "Confirm Spamming $sendto_string"]
[ad_scope_admin_context_bar [list "spam-index" "Spam Admin"] \
	[list "spam?[export_url_vars sendto]"  "Spam $sendto_string"] Confirm] 
<hr>
"
set creation_date [db_string get_current_day "select to_char(sysdate, 'ddth Month,YYYY  HH:MI:SS am') from dual"]

set sender_id [ad_verify_and_get_user_id]

if { [lsearch $sendto "all"] != -1 } {
    set role_clause ""
} else {
    foreach recipient_role $sendto {
	append ug_role_clause "ug.role=:recipient_role "
    }
    set role_clause "and ("
    append role_clause [join $ug_role_clause " or "] ")"
}

set counter [db_string get_count_from_ug "
    select count(*) from ( select  distinct email 
    from user_group_map ug, users_spammable u
	where ug.group_id = :group_id
	$role_clause
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = :group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  :sender_id))"]
 
# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [db_string get_unique_key "select group_spam_id_sequence.nextval from dual"]

set message [spam_wrap_text $message 80]

append html "

<form method=POST action=\"spam-send\">
[export_form_vars sendto spam_id from_address subject message]

<blockquote>
<table border=0 cellpadding=5>

<tr><th align=left>Date</th><td>$creation_date </td></tr>

<tr><th align=left>From </th><td>$from_address</td></tr>

<tr><th align=left>To </th><td>$sendto_string </td></tr>

<tr><th align=left>Number of Recipients </th><td>$counter</td></tr>

<tr><th align=left>Subject </th><td>[ad_decode $subject "" none $subject]</td></tr>

<tr><th align=left valign=top>Message </th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>

</table>
</blockquote>
 
<center>
<input type=submit value=\"Send Email\">
</center>

</form>
"

doc_return  200 text/html "
$page_html
<blockquote>
$html
</blockquote>

[ad_scope_admin_footer]
"
