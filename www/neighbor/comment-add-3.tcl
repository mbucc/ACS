# /www/neighbor/comment-add-3.tcl

ad_page_contract {
    Inserts comments into the general_comments table.

    @param neighbor_to_neighbor_id id of the neighbor_to_neighbor item to comment on.
    @param content the user-entered comment, in plain-text or HTML format.
    @param comment_id id of the new comment, generated on comment-add.tcl.
    @param html_p is the comment HTML-formatted? (t or f)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id comment-add-3.tcl,v 3.4.2.6 2001/01/11 19:43:38 khy Exp
} {
    neighbor_to_neighbor_id:integer
    content
    comment_id:integer,notnull,verify
    html_p
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
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

# user has input something, so continue on

# assign necessary data for insert

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    ad_returnredirect /register/
    return
}

set originating_ip [ns_conn peeraddr]

if { [ad_parameter CommentApprovalPolicy neighbor] == "open"} {
    set approved_p "t"
} else {
    set approved_p "f"
}



set one_line_item_desc [db_string n_to_n_comment_descrip "select about || ' : ' || title from neighbor_to_neighbor where neighbor_to_neighbor_id = :neighbor_to_neighbor_id"]

if [catch { ad_general_comment_add $comment_id "neighbor_to_neighbor" $neighbor_to_neighbor_id $one_line_item_desc $content $user_id $originating_ip $approved_p $html_p } errmsg] {
    # Oracle choked on the insert
     if { [db_string n_to_n_comment_count "select count(*) from general_comments where comment_id = :comment_id"] == 0 } {
	# there was an error with comment insert other than a duplication
	ad_return_error "Error in inserting comment" "We were unable to insert your comment in the database.  Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
        return
     }
}

# either we were successful in doing the insert or the user hit submit
# twice and we don't really care

if { $approved_p == "t" } {
    # user will see it immediately
    ad_returnredirect "view-one?[export_url_vars neighbor_to_neighbor_id]"
} else {
    db_1row unused "select about,title,n.category_id,u.email as maintainer_email
from neighbor_to_neighbor n, n_to_n_primary_categories pc, users u 
where neighbor_to_neighbor_id = :neighbor_to_neighbor_id
and n.category_id = pc.category_id
and pc.primary_maintainer_id = u.user_id"
    


doc_return  200 text/html "[neighbor_header "Thank You"]

<h2>Thank you</h2>

for your comment on <A HREF=\"view-one?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>

<hr>

You will find your comment on the site as soon as it has been approved
by the moderator.

[neighbor_footer $maintainer_email]
"
}
