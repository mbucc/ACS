# comment-add-2.tcl

ad_page_contract {
    2nd page in neighbor_to_neighbor comment-adding process.

    @param neighbor_to_neighbor_id id of the neighbor_to_neighbor item to comment on.
    @param content the user-entered comment, in plain-text or HTML format.
    @param comment_id id of the new comment, generated on comment-add.tcl.
    @param html_p is the comment HTML-formatted? (t or f)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id comment-add-2.tcl,v 3.3.2.5 2001/01/11 19:44:31 khy Exp
} {
    neighbor_to_neighbor_id:integer
    content
    comment_id:integer,verify,notnull
    html_p
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

#check for the user cookie

set user_id [ad_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect /register/    
    return
}


# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

#check for bad html
set naughty_html_text [ad_check_for_naughty_html $content]

if {![empty_string_p $naughty_html_text]} {
    ad_return_complaint 1 "<li>$naughty_html_text"
    return
}

    
db_1row n_to_n_tem_info "select about, title from neighbor_to_neighbor where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"

db_release_unused_handles


set doc_body "[ad_header "Confirm comment on <i>$about : $title</i>" ]

<h2>Confirm comment</h2>

on <A HREF=\"view-one?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>

<hr>

The following is your comment as it would appear on the page <i>$title</i>.
If it looks incorrect, please use the back button on your browser to return and
correct it.  Otherwise, press \"Continue\".
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


append doc_body "<form action=comment-add-3 method=post>
<center>
<input type=submit name=submit value=\"Confirm\">
</center>
[export_entire_form]
</form>
[ad_footer]
"

doc_return  200 text/html $doc_body
