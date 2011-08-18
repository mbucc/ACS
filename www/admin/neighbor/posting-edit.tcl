# $Id: posting-edit.tcl,v 3.0 2000/02/06 03:26:11 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables

# comment_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select comment_id, content, general_comments.html_p as comment_html_p, approved_p
from general_comments
where comment_id = $comment_id"]


if { $selection == "" } {
   ad_return_error "Can't find comment" "Can't find comment $comment_id"
   return
}

set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Edit comment" ]

<h2>Edit comment </h2>

<hr>

<blockquote>
<form action=edit-2.tcl method=post>
<textarea name=content cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $content]</textarea><br>
Text above is
<select name=html_p>
 [ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $comment_html_p]
</select>
<br>
Approval status
<select name=approved_p>
 [ad_generic_optionlist {"Approved" "Unapproved"} {"t" "f"} $approved_p]
</select>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars comment_id]
</form>
</blockquote>
[ad_admin_footer]
"
