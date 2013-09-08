# File: /groups/group/spam-confirm.tcl
ad_page_contract {
    @param sendto recipient of the email
    @param subject subject line
    @param message the message

    @cvs-id spam-confirm.tcl,v 3.7.2.10 2000/09/22 01:38:14 kevin Exp
} {
    sendto:notnull
    from_address:notnull
    subject:optional
    message:optional,html
}

set group_name [ns_set get $group_vars_set group_name]

ad_scope_authorize $scope all group_member none

set exception_count 0
set exception_text ""

if {[empty_string_p $subject] && [empty_string_p $message]} {
    incr exception_count
    append exception_text "<li>The contents of your message and subject line is the empty string. <br> You must send something in the message body or subject line."
}

if {$exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set sendto_string [ad_decode $sendto "members" "Group Members" "all" "Everyone in the group" "administrators" "Group Administrators" $sendto]

set creation_date [db_string get_creation_date "select to_char(sysdate, 'ddth Month,YYYY  HH:MI:SS am') from dual"]

set sender_id [ad_verify_and_get_user_id]

if { [lsearch $sendto "all"] != -1 } {
    set role_clause ""
} else {
    set count 0
    foreach recipient_role $sendto {
	set ug_role_$count $recipient_role
	lappend ug_role_clause "ug.role=:ug_role_$count"
	incr count
    }
    set role_clause "and ("
    append role_clause [join $ug_role_clause " or "] )
}

set counter [db_string get_count_emails "
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

if { $counter == 0 } {
    ad_return_error "No members" "There are no members in the group matching your selection $sendto_string"
    return
}

# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [db_string get_spam_id_seq "select group_spam_id_sequence.nextval from dual"]

# strips ctrl-m's, makes linebreaks at >= 80 cols when possible, without
# destroying urls or other long strings
set message [spam_wrap_text $message 80]

append html "

<form method=POST action=\"spam-send\">
[export_form_vars sendto spam_id from_address subject message]

<blockquote>

<table border=0 cellpadding=5 >

<tr><th align=left>Date</th><td>$creation_date </td></tr>

<tr><th align=left>To </th><td>$sendto_string</td></tr>
<tr><th align=left>From </th><td>$from_address</td></tr>


<tr><th align=left>Subject </th><td>[ad_decode $subject "" none $subject]</td></tr>

<tr><th align=left valign=top>Message </th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>

<tr><th align=left>Number of recipients </th><td>$counter</td></tr>

</table>
</blockquote>

<center>
<input type=submit value=\"Send Email\">
</center>

</form>
"

set page_content "
[ad_scope_header "Confirm Sending Email"]
[ad_scope_page_title "Confirm Email to Group $sendto_string"]
[ad_scope_context_bar_ws_or_index [list index.tcl $group_name] [list spam-index.tcl "Email"] [list "spam.tcl?[export_url_vars sendto]"  "Group $sendto_string"] Confirm]
<hr>

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"



doc_return  200 text/html $page_content

