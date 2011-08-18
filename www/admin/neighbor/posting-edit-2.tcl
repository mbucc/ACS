# $Id: posting-edit-2.tcl,v 3.0 2000/02/06 03:26:10 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# comment_id, content, html_p, approved_p

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

# user has input something, so continue on

set db [ns_db gethandle]
set user_id [ad_get_user_id]

if [catch { ns_db dml $db "begin transaction" 
            # insert into the audit table
            ns_db dml $db "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"
            ns_ora clob_dml $db "update general_comments
set content = empty_clob(), html_p = '$html_p', approved_p = '$approved_p'
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

ns_return 200 text/html "done"
