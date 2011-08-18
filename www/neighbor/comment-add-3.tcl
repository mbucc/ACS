# $Id: comment-add-3.tcl,v 3.0.4.1 2000/04/28 15:11:12 carsten Exp $
#
# comment-add-3.tcl
#
# by philg@mit.edu many years ago 
#
# actually inserts a comment into the general_comments table
#

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


set_the_usual_form_variables

# neighbor_to_neighbor_id, content, comment_id, content, html_p

# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_return_complaint 1 "<li>the comment field was empty"
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

set db [ns_db gethandle]

set one_line_item_desc [database_to_tcl_string $db "select about || ' : ' || title from neighbor_to_neighbor where neighbor_to_neighbor_id = $neighbor_to_neighbor_id"]

if [catch { ad_general_comment_add $db $comment_id "neighbor_to_neighbor" $neighbor_to_neighbor_id $one_line_item_desc $content $user_id $originating_ip $approved_p $html_p } errmsg] {
    # Oracle choked on the insert
     if { [database_to_tcl_string $db "select count(*) from general_comments where comment_id = $comment_id"] == 0 } {
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
    ad_returnredirect "view-one.tcl?[export_url_vars neighbor_to_neighbor_id]"
} else {
    set selection [ns_db 1row $db "select about,title,n.category_id,u.email as maintainer_email
from neighbor_to_neighbor n, n_to_n_primary_categories pc, users u 
where neighbor_to_neighbor_id = $neighbor_to_neighbor_id
and n.category_id = pc.category_id
and pc.primary_maintainer_id = u.user_id"]
    set_variables_after_query

    ns_return 200 text/html "[neighbor_header "Thank You"]

<h2>Thank you</h2>

for your comment on <A HREF=\"view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$about : $title</a>

<hr>

You will find your comment on the site as soon as it has been approved
by the moderator.

[neighbor_footer $maintainer_email]
"
}
