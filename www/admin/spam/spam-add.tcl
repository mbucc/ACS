# $Id: spam-add.tcl,v 3.3 2000/03/09 10:25:09 hqm Exp $
# spam-add.tcl
#
# hqm@arsdigita.com
#
# Compose a spam to be scheduled to be sent to a user class

set_the_usual_form_variables 0

#maybe html_p

ReturnHeaders

ns_write "[ad_admin_header "Add a spam"]

<h2>Spam</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Add a spam"]

<hr>
<p>
"

set db [ns_db gethandle]
 
# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select spam_id_sequence.nextval from dual"]

set userclass_options [db_html_select_value_options $db "select user_class_id, name from user_classes order by name"]

if {[empty_string_p $userclass_options]} {
    ns_write "Sorry, there are no user-classes defined yet, and you need to specify a user-class as the target of a spam. You can define user-classes from the /admin/users menu.
<p>
    [ad_admin_footer]"
    return
}


ns_write "

<form method=POST action=\"/admin/spam/spam-confirm.tcl\">

<input type=hidden name=spam_id value=\"$spam_id\">

<table>
<tr><th align=right>User Class</th><td><select name=user_class_id>
$userclass_options
</select></td></tr>
<tr><th align=right>Scheduled Send Date:</th><td>[_ns_dateentrywidget "send_date"]</td></tr>
<tr><th align=right>Scheduled Send Time:</th><td> [_ns_timeentrywidget "send_date"]</td></tr>

<tr><th align=right>From:</th><td><input name=from_address type=text size=30 value=\"[database_to_tcl_string $db "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

<tr><th align=right>Subject:</th><td> <input name=subject type=text size=50></td></tr>

<tr><th align=right valign=top>Message (plain text):</th><td>
<textarea name=message rows=10 cols=80 wrap=soft></textarea>
</td></tr>
"


if {[info exists html_p] && [string compare $html_p "t"] == 0} {
    ns_write  "<tr><th align=right valign=top>Message (html):</th><td>
<textarea name=message_html rows=10 cols=70 wrap=off></textarea>
</td></tr>
<tr><th align=right valign=top>Message (AOL):</th><td>
<textarea name=message_aol rows=10 cols=70 wrap=off></textarea>
</td></tr>"
}

ns_write "
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


