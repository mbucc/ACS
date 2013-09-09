# admin/neighbor/posting-delete-2.tcl
ad_page_contract {
    I don't think this ever gets used
    @cvs-id: posting-delete-2.tcl,v 3.1.2.4 2000/09/22 01:35:42 kevin Exp
    @author unknown
    @creation-date 2000-07-18
} {
    comment_id:integer
    content:html
    html_p
    submit
    {return_url:optional}

}

# posting-delete-2.tcl,v 3.1.2.4 2000/09/22 01:35:42 kevin Exp
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


if {![info exists return_url]} {
    set return_url ""
}

if {[regexp -nocase "cancel" $submit]} {
    doc_return  200 text/html "comment not deleted"    
    return
}


set user_id [ad_get_user_id]

if [catch { db_transaction { 
            # insert into the audit table
            db_dml unused "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = :comment_id"

            db_dml unused "delete from general_comments where
comment_id=:comment_id"

            } } errmsg] {

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

doc_return 200 text/html "done"

