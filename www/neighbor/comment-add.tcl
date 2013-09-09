# /www/neighbor/comment-add.tcl

ad_page_contract {
    Add a comment to a neighbor-to-neighbor item.

    @param neighbor-to-neighbor_id id of the item to comment on.
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id comment-add.tcl,v 3.4.2.5 2001/01/11 19:49:25 khy Exp
} {
    neighbor_to_neighbor_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/?return_url=[ns_urlencode [ns_conn url]]?[export_url_vars neighbor_to_neighbor_id]
    return
}



set row_exists_p [db_0or1row unused "select about, title, body, html_p
from neighbor_to_neighbor
where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"]

if { $row_exists_p==0 } {
    ad_return_error "Can't find the neighbor-to-neighbor item" "Can't find neighbor-to-neighbor #$neighbor_to_neighbor_id"
    return
}
set comment_id [db_string general_comment_id "select general_comment_id_sequence.nextval from dual"]

set doc_body "[ad_header "Add a comment to $about : $title" ]

<h2>Add a comment</h2>

to <A HREF=\"view-one?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>
<hr>

<blockquote>
[util_maybe_convert_to_html $body $html_p]
</blockquote>
<form action=comment-add-2 method=post>
What comment  would you like to add to this item?<br>
<textarea name=content cols=50 rows=5 wrap=soft>
</textarea><br>
Text above is
<select name=html_p><option value=f>Plain Text<option value=t>HTML</select>
<br>
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
[export_form_vars neighbor_to_neighbor_id]
[export_form_vars -sign comment_id]
</form>

[ad_footer]
"



doc_return  200 text/html $doc_body