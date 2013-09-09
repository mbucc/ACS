# www/admin/spam/spam-create.tcl
ad_page_contract {

 Compose a spam to be scheduled to be sent to a user class.
 Doesn't actually send, just creates a new row in spam_history.

    @author hqm@arsdigita.com
    @cvs-id spam-create.tcl,v 3.3.2.8 2001/01/12 00:07:11 khy Exp
} { 
}



# make sure they're authorized

set user_id [ad_verify_and_get_user_id]

append page_content "[ad_admin_header "Create New Message"]

<h2>Create a new message</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Create New Message"]

<hr>
<p>
"

 
# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [db_string new_spam_id "select spam_id_sequence.nextval from dual"]

append page_content "

<form method=POST action=\"/admin/spam/spam-create-2\">

[export_form_vars -sign spam_id]
<table>
<tr><th align=right>User Class</th><td>: <select name=user_class_id>
[db_html_select_value_options user_class_select_options "select user_class_id, name from user_classes order by name"]
</select></td></tr>
<tr><th align=right>From:</th><td><input name=from_address type=text size=30 value=\"[db_string user_email "select email from users where user_id = :user_id"]\"></td></tr>

<tr><th align=right>Subject:</th><td> <input name=subject type=text size=50></td></tr>
<tr><th align=right>Scheduled Send Date:</th><td>[_ns_dateentrywidget "send_date"]</td></tr>
<tr><th align=right>Scheduled Send Time:</th><td> [_ns_timeentrywidget "send_date"]</td></tr>

</table>

<center>

<input type=submit value=\"Create New Message\">

</center>

</form>
<p>

[ad_admin_footer]"



doc_return  200 text/html $page_content


