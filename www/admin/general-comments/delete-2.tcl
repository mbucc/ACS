# www/admin/general-comments/delete-2.tcl

ad_page_contract {
    Updates audit table and delete comment

    @cvs-id delete-2.tcl,v 3.0.12.5 2000/07/29 22:23:58 pihman Exp
    @param comment_id The comment to delete
    @param return_url The page to return to after deleting the comment
    @param submit A confirmation flag for deleting a comment ('cancel' or 'proceed')

} {
    comment_id:integer
    {return_url "index.tcl"}
    submit
}


if {[regexp -nocase "cancel" $submit]} {
    ad_returnredirect $return_url
    return
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}
set user_id [ad_verify_and_get_user_id] 
ad_maybe_redirect_for_registration
set peeraddr [ns_conn peeraddr]


db_transaction { 

    # insert into the audit table
    db_dml general_comments_audit_insert "insert into 
         general_comments_audit
         (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
         select comment_id, user_id, :peeraddr, sysdate, modified_date, content 
           from general_comments 
           where comment_id = :comment_id"

    db_dml general_comments_comment_dlete "delete from 
         general_comments where comment_id = :comment_id"
	    
}

db_release_unused_handles
ad_returnredirect $return_url

