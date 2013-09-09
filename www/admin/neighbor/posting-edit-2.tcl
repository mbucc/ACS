#admin/neighbor/posting-edit-2.tcl
ad_page_contract {
    I can't find anywhere that links here
    @cvs_id posting-edit-2.tcl,v 3.0.12.5 2000/09/22 01:35:42 kevin Exp
    @author unknown
} {
    comment_id
    content:html
    html_p:optional
    {approved_p:optional}
}


# posting-edit-2.tcl,v 3.0.12.5 2000/09/22 01:35:42 kevin Exp
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


set user_id [ad_get_user_id]

if [catch { db_transaction { 
            # insert into the audit table
            db_dml unused "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = :comment_id"
            db_dml  neighor_postin_clob_update "update general_comments
set content = empty_clob(), html_p = ':html_p', approved_p = ':approved_p'
where comment_id = :comment_id returning content into :1" -clobs [list $content]
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


doc_return  200 text/html "done"


