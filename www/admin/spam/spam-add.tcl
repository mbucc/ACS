# www/admin/spam/spam-add.tcl

ad_page_contract {
  Compose a spam to be scheduled to be sent to a user class
   
    @param html_p <em>optional</em> If html_p == "t" allow user to enter HTML alternative content for message
    @author hqm@arsdigita.com
    @cvs-id spam-add.tcl,v 3.5.2.6 2001/01/12 00:17:21 khy Exp
} {
    {html_p f}
}

append pagebody  "[ad_admin_header "Add a spam"]

<h2>Spam</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Add a spam"]

<hr>
<p>
"

# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [db_string "next_spam_id" "select spam_id_sequence.nextval from dual"]

set userclass_options [db_html_select_value_options user_class_select_options "select user_class_id, name from user_classes order by name"]


if {[empty_string_p $userclass_options]} {
    append pagebody  "Sorry, there are no user-classes defined yet, and you need to specify a user-class as the target of a spam. You can define user-classes from the <a href=/admin/users>/admin/users</a> menu.
<p>
    [ad_admin_footer]"
    
    doc_return  200 text/html $pagebody
    ad_script_abort
}

append pagebody  "

<form method=POST action=\"/admin/spam/spam-confirm\">

[export_form_vars -sign spam_id]

<table>
<tr><th align=right>User Class</th><td><select name=user_class_id>
$userclass_options
</select></td></tr>
<tr><th align=right>Scheduled Send Date:</th><td>[_ns_dateentrywidget "send_date"]</td></tr>
<tr><th align=right>Scheduled Send Time:</th><td> [_ns_timeentrywidget "send_date"]</td></tr>

<tr><th align=right>From:</th><td><input name=from_address type=text size=30 value=\"[db_string "default_from_address" "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

<tr><th align=right>Subject:</th><td> <input name=subject type=text size=50></td></tr>

<tr><th align=right valign=top>Message (plain text):</th><td>
<textarea name=message rows=10 cols=80 wrap=soft></textarea>
</td></tr>
"

if {[string compare $html_p "t"] == 0} {
    append pagebody   "<tr><th align=right valign=top>Message (html):</th><td>
<textarea name=message_html rows=10 cols=70 wrap=off></textarea>
</td></tr>
<tr><th align=right valign=top>Message (AOL):</th><td>
<textarea name=message_aol rows=10 cols=70 wrap=off></textarea>
</td></tr>"
}

append pagebody  "
<tr>
<th></th>
<td><input type=checkbox name=template_p value=t> <b>Is this message a Tcl Template?</b> <br><blockquote>If so, make sure you have put backslashes before any \$ or \[\]'s characters if you don't want them to be evaluated as Tcl commands. </blockquote> </td>
</tr>
</table>

<p>
<center>

<input type=submit value=\"Queue Mail Message\">

</center>

</form>
<p>

[ad_admin_footer]"


db_release_unused_handles
doc_return 200 text/html $pagebody

