# $Id: spam-add-from-file.tcl,v 3.0 2000/02/06 03:30:16 ron Exp $
# spam-add-from-file.tcl
#
# hqm@arsdigita.com
#
# Compose a spam to be scheduled to be sent to a user class

set_the_usual_form_variables 0

#maybe html_p

ReturnHeaders

append pagebody "[ad_admin_header "Send spam from file(s)"]

<h2>Spam</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Send spam from file(s)"]

<hr>
<p>
"

set db [ns_db gethandle]
 

set userclass_options [db_html_select_value_options $db "select user_class_id, name from user_classes order by name"]


if {[empty_string_p $userclass_options]} {
    ns_write "$pagebody 
Sorry, there are no user-classes defined yet, and you need to specify a user-class as the target of a spam. You can define user-classes from the /admin/users menu.
<p>
    [ad_admin_footer]"
    return
}



# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select spam_id_sequence.nextval from dual"]



append pagebody "

<form method=POST action=\"/admin/spam/spam-add-from-file-2.tcl\">

<input type=hidden name=spam_id value=\"$spam_id\">
<input type=hidden name=from_file_p value=t>


<table border=0>
<tr><th align=right>User Class</th><td>: <select name=user_class_id>
$userclass_options
</select></td></tr>
<tr><th align=right>Scheduled Send Date:</th><td>[_ns_dateentrywidget "send_date"]</td></tr>
<tr><th align=right>Scheduled Send Time:</th><td> [_ns_timeentrywidget "send_date"]</td></tr>

<tr><th align=right>From:</th><td><input name=from_address type=text size=30 value=\"[database_to_tcl_string $db "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

<tr><th align=right>Subject:</th><td> <input name=subject type=text size=50></td></tr>
<tr><td colspan=2>Enter file names in directory [spam_file_location ""]<br>
example: <code>welcome-new-user.txt</code></tr>
<tr><th align=right>Filename (plain text mesg):</th><td> <input name=path_plain type=text size=50></td></tr>
<tr><th align=right>Filename (HTML msg):</th><td> <input name=path_html type=text size=50></td></tr>
<tr><th align=right>Filename (AOL msg):</th><td> <input name=path_aol type=text size=50></td></tr>
<tr>
<th></th>
<td><input type=checkbox name=template_p value=t> <b>Is this message a Tcl Template?</b> </td>
</tr>

<tr><td colspan=2 align=center>

<input type=submit value=\"Queue Mail Message\">

</form>

</table>

<p>

[ad_admin_footer]"


ns_write $pagebody