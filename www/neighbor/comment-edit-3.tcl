# comment-edit-3.tcl

ad_page_contract {
    Insert the new, edited comment into the DB.

    @param content the user-entered comment, in plain-text or HTML format.
    @param comment_id id of the new comment, generated on comment-add.tcl.
    @param html_p is the comment HTML-formatted? (t or f)
    @author Philip Greenspun (philg@mit.edu)
    @creation-date ?
    @cvs-id comment-edit-3.tcl,v 3.2.2.3 2000/07/21 04:03:00 ron Exp
} {
    comment_id:integer
    content
    html_p
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

# user has input something, so continue on

#check for bad html
set naughty_html_text [ad_check_for_naughty_html $content]

if {![empty_string_p $naughty_html_text]} {
    ad_return_complaint 1 "<li>$naughty_html_text"
    return
}

set user_id [ad_verify_and_get_user_id]

db_1row n_to_n_comment_info "select neighbor_to_neighbor_id, general_comments.user_id as comment_user_id
from neighbor_to_neighbor, general_comments
where comment_id = :comment_id
and neighbor_to_neighbor_id = on_what_id"


# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}

set comment_ip_addr [ns_conn peeraddr]

if [catch { db_transaction { 
            # insert into the audit table
            db_dml n_to_n_gc_info_update "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, user_id, :comment_ip_addr, sysdate, modified_date, content from general_comments where comment_id = :comment_id"
            db_dml n_to_n_gc_clob_update "update general_comments
set content = empty_clob(), html_p = :html_p
where comment_id = :comment_id returning content into :1" -clobs [list $content]
          }   } errmsg] {

	# there was some other error with the comment update
	ad_return_error "Error updating comment" "We couldn't update your comment. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
"
return
}

db_release_unused_handles

ad_returnredirect "view-one?[export_url_vars neighbor_to_neighbor_id]"
