# www/admin/general-comments/edit-2.tcl

ad_page_contract {
    Updates the data-base with a edited comment information

    @cvs-id edit-2.tcl,v 3.2.2.7 2000/07/29 22:51:48 pihman Exp
    @param comment_id The comment to edit
    @param content The edited comment
    @param html_p A flag for whether the edited comment is to be displayed as html
    @param approved_p A flag marking the comment as approved or unapproved

} {
    comment_id:integer
    content:html
    html_p
    approved_p
}

set user_id [ad_verify_and_get_user_id] 
ad_maybe_redirect_for_registration
set peeraddr [ns_conn peeraddr]

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

# user has input something, so continue on

db_transaction {

    # insert into the audit table
    db_dml general_comment_audit_insert \
	"insert into general_comments_audit 
        (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
        select comment_id, :user_id, :peeraddr, sysdate, modified_date, content 
          from general_comments 
          where comment_id = :comment_id" 

    ###!!!!!!!!!!!!!!NEED TO CHANGE THIS TO CLOB

    db_dml general_comment_update \
	"update general_comments
         set content = :content, html_p = :html_p, approved_p = :approved_p
         where comment_id = :comment_id"   
}


db_release_unused_handles
ad_returnredirect index.tcl
