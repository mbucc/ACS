# $Id: comment-edit.tcl,v 3.0.4.1 2000/04/28 15:11:13 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables

# comment_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select comment_id, content, general_comments.html_p as comment_html_p, user_id as comment_user_id, body, neighbor_to_neighbor_id, about || ' : ' || title as neighbor_title, n.html_p as neighbor_html_p
from general_comments, neighbor_to_neighbor n
where comment_id = $comment_id
and n.neighbor_to_neighbor_id = general_comments.on_what_id"]

set_variables_after_query

#check for the user cookie
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/index.tcl?return_url=[ns_urlencode [ns_conn url]]?comment_id=$comment_id 
}

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}
ReturnHeaders

ns_write "[ad_header "Edit comment on $neighbor_title" ]

<h2>Edit comment </h2>
on <A HREF=\"view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$neighbor_title</a>
<hr>

<blockquote>
[util_maybe_convert_to_html $body $neighbor_html_p]
<form action=comment-edit-2.tcl method=post>
Edit your comment on the above item.<br>
<textarea name=content cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $content]</textarea><br>
Text above is
<select name=html_p>
 [ad_generic_optionlist {"Plain Text" "HTML"} {"f" "t"} $comment_html_p]
</select>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars comment_id]
</form>
</blockquote>
[ad_footer]
"
