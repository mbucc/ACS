# comment-edit-2.tcl

ad_page_contract {
    View and verify the edited comment.
    
    @param content the user-entered comment, in plain-text or HTML format.
    @param comment_id id of the new comment, generated on comment-add.tcl.
    @param html_p is the comment HTML-formatted? (t or f)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id comment-edit-2.tcl,v 3.2.2.4 2000/09/22 01:38:54 kevin Exp
} {
    content
    html_p
    comment_id:integer
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

#check for bad html
set naughty_html_text [ad_check_for_naughty_html $content]

if {![empty_string_p $naughty_html_text]} {
    ad_return_complaint 1 "<li>$naughty_html_text"
    return
}

set user_id [ad_verify_and_get_user_id]

db_1row n_to_n_item_info "select about || ' : ' || title as title, neighbor_to_neighbor_id, general_comments.user_id as comment_user_id
from neighbor_to_neighbor n, general_comments
where comment_id = :comment_id
and n.neighbor_to_neighbor_id = general_comments.on_what_id"]

db_release_unused_handles

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}



set doc_body "[ad_header "Verify comment on <i>$title</i>" ]

<h2>Verify comment</h2>
on <A HREF=\"view-one?[export_url_vars neighbor_to_neighbor_id]\">$title</A>
<hr>

The following is your comment as it would appear on the story
<i>$title</i>.  If it looks incorrect, please use the back button on
your browser to return and correct it.  Otherwise, press \"Continue\".
<p>

<blockquote>"

if { [info exists html_p] && $html_p == "t" } {
    append doc_body "$content
</blockquote>
Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
} else {
    append doc_body "[util_convert_plaintext_to_html $content]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

append doc_body "<center>
<form action=comment-edit-3 method=post>
<input type=submit name=submit value=\"Continue\">
[export_form_vars comment_id content html_p]
</center>
</form>
[ad_footer]
"

doc_return  200 text/html $doc_body