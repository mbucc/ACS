# File: /groups/group/spam-confirm.tcl
# Date: Fri Jan 14 19:27:42 EST 2000
# Contact: ahmeds@mit.edu
# Purpose: this is the group spam confirm page
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: spam-confirm.tcl,v 3.3 2000/03/12 09:48:47 hqm Exp $

set_the_usual_form_variables 0
# sendto subject message

set group_name [ns_set get $group_vars_set group_name]

set db [ns_db gethandle]

ad_scope_authorize $db $scope all group_member none

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

set sendto_string [ad_decode $sendto "members" "Members" "Administrators"]


ReturnHeaders 

ns_write "
[ad_scope_header "Confirm Sending Email" $db]
[ad_scope_page_title "Confirm Email to Group $sendto_string" $db]
[ad_scope_context_bar_ws_or_index [list index.tcl $group_name] [list spam-index.tcl "Email"] [list "spam.tcl?[export_url_vars sendto]"  "Group $sendto_string"] Confirm]
<hr>
"

set creation_date [database_to_tcl_string $db "select to_char(sysdate, 'ddth Month,YYYY  HH:MI:SS am') from dual"]

set sender_id [ad_verify_and_get_user_id $db]

set role_clause [ad_decode $sendto "members" "" "and ug.role='administrator'"]

set counter [database_to_tcl_string $db "
    select count(*)
    from user_group_map ug, users_spammable u
	where ug.group_id = $group_id
	$role_clause
	and ug.user_id = u.user_id
	and not exists ( select 1 
	                 from group_member_email_preferences
                         where group_id = $group_id
	                 and user_id =  u.user_id 
                         and dont_spam_me_p = 't')
        and not exists ( select 1 
	                 from user_user_bozo_filter
                         where origin_user_id = u.user_id 
	                 and target_user_id =  $sender_id)"]
 
# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select group_spam_id_sequence.nextval from dual"]

# strips ctrl-m's, makes linebreaks at >= 80 cols when possible, without
# destroying urls or other long strings
set message [spam_wrap_text $message 80]

append html "

<form method=POST action=\"spam-send.tcl\">
[export_form_vars sendto spam_id from_address subject message]

<blockquote>

<table border=0 cellpadding=5 >

<tr><th align=left>Date</th><td>$creation_date </td></tr>

<tr><th align=left>To </th><td>$sendto_string of $group_name group</td></tr>
<tr><th align=left>From </th><td>$from_address</td></tr>


<tr><th align=left>Subject </th><td>$subject</td></tr>

<tr><th align=left valign=top>Message </th><td>
<pre>[ns_quotehtml $message]</pre>
</td></tr>

<tr><th align=left>Number of recipients </th><td>$counter</td></tr>

</table>

</blockquote>
<center>
<input type=submit value=\"Send Email\">

</center>
"


ns_write "

<blockquote>
$html
</blockquote>

[ad_scope_footer]
"






