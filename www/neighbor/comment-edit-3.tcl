# $Id: comment-edit-3.tcl,v 3.0.4.1 2000/04/28 15:11:13 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# comment_id, content, html_p

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

# user has input something, so continue on

set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

set selection [ns_db 1row $db "select neighbor_to_neighbor_id, general_comments.user_id as comment_user_id
from neighbor_to_neighbor, general_comments
where comment_id = $comment_id
and neighbor_to_neighbor_id = on_what_id"]
set_variables_after_query

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}

if [catch { ns_db dml $db "begin transaction" 
            # insert into the audit table
            ns_db dml $db "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"
            ns_ora clob_dml $db "update general_comments
set content = empty_clob(), html_p = '$html_p'
where comment_id = $comment_id returning content into :1" "$content"
            ns_db dml $db "end transaction" } errmsg] {

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

ad_returnredirect "view-one.tcl?[export_url_vars neighbor_to_neighbor_id]"
