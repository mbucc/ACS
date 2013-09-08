# comment-edit.tcl

ad_page_contract {
    Edit a comment you entered.

    @param comment_id id of the comment to edit.
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id comment-edit.tcl,v 3.3.2.4 2000/09/22 01:38:54 kevin Exp
} {
    comment_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

db_1row n_to_n_comment_disp "select comment_id, content, general_comments.html_p as comment_html_p, user_id as comment_user_id, body, neighbor_to_neighbor_id, about || ' : ' || title as neighbor_title, n.html_p as neighbor_html_p
from general_comments, neighbor_to_neighbor n
where comment_id = :comment_id
and n.neighbor_to_neighbor_id = general_comments.on_what_id"]

db_release_unused_handles

#check for the user cookie
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/?return_url=[ns_urlencode [ns_conn url]]?comment_id=$comment_id 
}

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}


set doc_body "[ad_header "Edit comment on $neighbor_title" ]

<h2>Edit comment </h2>
on <A HREF=\"view-one?[export_url_vars neighbor_to_neighbor_id]\">$neighbor_title</a>
<hr>

<blockquote>
[util_maybe_convert_to_html $body $neighbor_html_p]
<form action=comment-edit-2 method=post>
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

doc_return  200 text/html $doc_body