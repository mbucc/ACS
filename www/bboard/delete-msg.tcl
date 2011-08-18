# $Id: delete-msg.tcl,v 3.1.4.1 2000/04/28 15:09:42 carsten Exp $
set_form_variables

# msg_id is the key

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


set selection [ns_db 1row $db "select bboard_topics.topic, bboard.one_line, bboard.message, bboard.html_p, bboard.sort_key, bboard.user_id as miscreant_user_id, users.email, bboard.topic_id
from bboard, users, bboard_topics
where bboard.user_id = users.user_id
and bboard_topics.topic_id = bboard.topic_id
and msg_id = '$msg_id'"]
set_variables_after_query

set thread_id [string range $sort_key 0 5]

set notify [database_to_tcl_string $db "select decode(count(*), 0, 'f', 't') from bboard_thread_email_alerts where thread_id='$thread_id'"]

if { [bboard_get_topic_info] == -1 } {
    return
}


set admin_user_id [ad_verify_and_get_user_id]

if {$admin_user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_hardwired_url_stub]admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id"]
    return
}

if { ![bboard_user_is_admin_for_topic $db $admin_user_id $topic_id] } {
    ad_return_error "Unauthorized" "We think you aren't authorized to delete messages"
    return
}

set authenticated_user_email_address [database_to_tcl_string $db "select email from users where user_id = $admin_user_id"]


set dependent_key_form [dependent_sort_key_form $sort_key]

set dependent_ids [database_to_tcl_list $db "select msg_id from bboard where sort_key like '$dependent_key_form'"]

set n_dependents [llength $dependent_ids]

set deletion_list [lappend dependent_ids $msg_id]



if { $notify == "f" } {
    set notify_warning "<blockquote><font color=red>
Warning: this user has turned off notification; 
he or she might not have been emailed any responses.
</blockquote>
</font>
<p>"
} else {
    set notify_warning ""
}

if [ad_parameter EnabledP "member-value"] {
    # we're doing the member value thing, but first we have to figure
    # out if this was a top-level question or an answer
    if { [bboard_compute_msg_level $sort_key] == 0 } {
	# a question
	set duplicate_wad [mv_create_user_charge $miscreant_user_id $admin_user_id "question_dupe" $msg_id [ad_parameter QuestionDupeRate "member-value"]]
	set off_topic_wad [mv_create_user_charge $miscreant_user_id $admin_user_id "question_off_topic" $msg_id [ad_parameter QuestionOffTopicRate "member-value"]]
	set options [list [list "" "Don't charge user"] [list $duplicate_wad "Duplicate or other mistake"] [list $off_topic_wad "Off topic (did not read forum policy)"]]
    } else {
	# it was an answer
	set mistake_wad [mv_create_user_charge $miscreant_user_id $admin_user_id "answer_mistake" $msg_id [ad_parameter AnswerMistakeRate "member-value"]]
	set wrong_wad [mv_create_user_charge $miscreant_user_id $admin_user_id "answer_wrong" $msg_id [ad_parameter AnswerWrongRate "member-value"]]
	set options [list [list "" "Don't charge user"] [list $mistake_wad "Mistake of some kind, e.g., duplicate posting"] [list $wrong_wad "Wrong or misleading answer"]]
    }
    set member_value_section "<h3>Charge this user for his sins?</h3>
<select name=user_charge>\n"
    foreach sublist $options {
	set value [lindex $sublist 0]
	set visible_value [lindex $sublist 1]
	append member_value_section "<option value=\"[philg_quote_double_quotes $value]\">$visible_value\n"
    }
    append member_value_section "</select>
<br>
<br>
<br>"
} else {
    set member_value_section ""
}

ns_return 200 text/html "[ad_admin_header "Confirm Delete"]

<h3>Confirm Delete</h3>

<hr>

$notify_warning

Are you sure you want to delete

<blockquote>

<h3>Subject</h3>

$one_line (from $email)

<h3>Message</h3>

[util_maybe_convert_to_html $message $html_p]

</blockquote>

and its $n_dependents dependent messages from the bulletin
board?

<form method=post action=\"do-delete.tcl\">

[export_form_vars topic topic_id]
<input type=hidden name=explanation_to value=\"$email\">
<input type=hidden name=deletion_list value=\"$deletion_list\">

$member_value_section

<input type=submit name=submit_button value=\"Delete Message and Dependents\">

<p>

If you want, you can explain to $email why you're deleting his or her
thread:

<p>

From:  <input type=text name=explanation_from value=\"$authenticated_user_email_address\" size=30>

<p>

<textarea rows=14 cols=70 name=explanation wrap=physical>
I'm deleting your thread from the $topic forum because

For clarity, here's your original posting:

SUBJECT:  $one_line

BODY:  $message

</textarea>

<input type=submit name=submit_button value=\"Delete Message and Dependents; Then Send Email Explanation\">

</form>

[ad_footer]
"
