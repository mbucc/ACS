# $Id: delete.tcl,v 3.0 2000/02/06 03:23:24 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables

# comment_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select comment_id, content, general_comments.html_p as comment_html_p
from general_comments
where comment_id = $comment_id"]

if { $selection == "" } {
   ad_return_error "Can't find comment" "Can't find comment $comment_id"
   return
}

set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Really delete comment" ]

<h2>Really delete comment</h2>

<hr>


<form action=delete-2.tcl method=post>
Do you really wish to delete the following comment?
<blockquote>
[util_maybe_convert_to_html $content $comment_html_p]
</blockquote>
<center>
<input type=submit name=submit value=\"Proceed\">
<input type=submit name=submit value=\"Cancel\">
</center>
[export_form_vars comment_id]
</form>
[ad_admin_footer]
"
