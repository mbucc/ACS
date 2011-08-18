# $Id: spam-add-from-file-2.tcl,v 3.0 2000/02/06 03:30:15 ron Exp $
# spam-add-from-file.tcl
#
# hqm@arsdigita.com
#
# Compose a spam to be scheduled to be sent to a user class

set_the_usual_form_variables 0

#maybe html_p
# path_plain, path_html, path_aol

set path_plain [spam_file_location $path_plain]
set path_html [spam_file_location $path_html]
set path_aol [spam_file_location $path_aol]

if {[info exists template_p] && [string match $template_p "t"]} {
   set template_pretty "Yes"
} else {
    set template_p "f"
    set template_pretty "No" 
}


ReturnHeaders

append pagebody "[ad_admin_header "Send spam from file(s)"]

<h2>Spam</h2>

[ad_admin_context_bar [list "index.tcl" "Spam"] "Send spam from file(s)"]

<hr>
<p>
"

set db [ns_db gethandle]
 
# generate unique key here so we can handle the "user hit submit twice" case
set spam_id [database_to_tcl_string $db "select spam_id_sequence.nextval from dual"]


append pagebody "

<form method=POST action=\"/admin/spam/spam-confirm.tcl\">

<input type=hidden name=spam_id value=\"$spam_id\">
<input type=hidden name=from_file_p value=t>
[export_form_vars template_p]
"

append pagebody "
Plain Text File: $path_plain"

if { ![file readable $path_plain] || ![file isfile $path_plain] } {
    append pagebody " <font color=red>File not found or not readable!</font>"
}


append pagebody "<br>
HTML Source File: $path_html"

if { ![file readable $path_html] || ![file isfile $path_html]} {
    append pagebody " <font color=red>File not found or not readable!</font>"
}

append pagebody "<br>
AOL Source File: $path_aol
"

if { ![file readable $path_aol] || ![file isfile $path_aol] } {
    append pagebody " <font color=red>File not found or not readable!</font>"
}



append pagebody "


<table border=1>
<tr><th align=right>User Class</th><td>: <select name=user_class_id>
[db_html_select_value_options $db "select user_class_id, name from user_classes"]
</select></td></tr>
<tr><th align=right>Scheduled Send Date:</th><td>[_ns_dateentrywidget "send_date"]</td></tr>
<tr><th align=right>Scheduled Send Time:</th><td> [_ns_timeentrywidget "send_date"]</td></tr>

<tr><th align=right>Template?</th><td>$template_pretty</td></tr>
<tr><th align=right>From:</th><td><input name=from_address type=text size=30 value=\"[database_to_tcl_string $db "select email from users where user_id =[ad_get_user_id]"]\"></td></tr>

<tr><th align=right>Subject:</th><td> <input name=subject type=text size=50></td></tr>
<tr><td colspan=2 align=center>

<input type=submit value=\"Queue Mail Message\">

</form>
</tr>

<tr><th align=right valign=top>Message (plain text):</th><td>
<pre>[ns_quotehtml [read_file_as_string $path_plain]]</pre>
</td></tr>
<tr><th align=right valign=top>Message (html):</th><td>
[read_file_as_string $path_html]
</td></tr>
<tr><th align=right valign=top>Message (AOL):</th><td>
[read_file_as_string $path_aol]
</td></tr>"


append pagebody "
</table>

<p>

[ad_admin_footer]"


ns_write $pagebody