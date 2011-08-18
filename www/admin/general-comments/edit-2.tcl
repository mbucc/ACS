# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:09:04 carsten Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set admin_id [ad_verify_and_get_user_id] 
if { $admin_id == 0 } {
    # we don't know who this is administering, 
    # so we won't be able to audit properly
    ad_returnredirect "/register/"
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

if [catch { ns_db dml $db "begin transaction" 
            # insert into the audit table
            ns_db dml $db "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, $admin_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"
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

ns_return 200 text/html "[ad_admin_header "Done"]

<h2>Done</h2>

[ad_admin_context_bar [list "index.tcl" "General Comments"] "Edit"]

<hr>

[ad_admin_footer]
"
