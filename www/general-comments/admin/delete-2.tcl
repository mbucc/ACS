# /general-comments/admin/delete-2.tcl

ad_page_contract {
    Purpose:  delete the comment

    @author philg@mit.edu
    @author tarik@arsdigita.com
    @creation-date 01/06/99
    @cvs-id delete-2.tcl,v 3.1.6.3 2000/07/29 23:47:43 pihman Exp
    @param comment_id The comment to delete
    @param return_url The page to return to after the transaction
    @param submit Whether or not to proceed with the transaction ('proceed','cancel')

} {
    comment_id
    {return_url index.tcl}
    submit
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set 
#   are already set up in the environment by the ug_serve_section. 
# group_vars_set contains group related variables (group_id, group_name, 
#   group_short_name, group_admin_email, group_public_url, group_admin_url, 
#   group_public_root_url, group_admin_root_url, group_type_url_p, 
#   group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_scope_error_check
set user_id [general_comments_admin_authorize $comment_id]

if {[regexp -nocase "cancel" $submit]} {
    ad_returnredirect $return_url
    return
}

set ip_addr [ns_conn peeraddr]

if [catch { 
    db_transaction { 
	# insert into the audit table
	db_dml comment_insert "insert into general_comments_audit
        (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
        select comment_id, user_id, :ip_addr, sysdate, modified_date, content 
          from general_comments 
          where comment_id = :comment_id"
    
	db_dml comment_delete "
        delete from general_comments where
	  comment_id = :comment_id"
    }
} errmsg] {
    # there was some other error with the comment update
    ad_scope_return_error "Error updating comment" "We couldn't update your comment. Here is what the database returned:
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
ad_returnredirect $return_url


