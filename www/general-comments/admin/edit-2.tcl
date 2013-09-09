# www/general-comments/admin/edit-2.tcl

ad_page_contract {
    edit comment page

    @author philg@mit.edu
    @author tarik@arsdigita.com
    @creation-date 01/06/99
    @cvs-id edit-2.tcl,v 3.1.6.4 2000/09/22 01:38:02 kevin Exp
} {
    {scope ""}
    {group_id ""}
    {on_which_group ""}
    {on_what_id ""}
    {comment_id:integer}
    {content:html,notnull}
    {html_p}
    {approved_p}
    {return_url ""}
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

ad_scope_error_check 

set admin_id [general_comments_admin_authorize $comment_id]

if { $admin_id == 0 } {
    # we don't know who this is administering, 
    # so we won't be able to audit properly
    ad_returnredirect "/register/"
    return
}

# check for bad input
if  { [empty_string_p $content] } { 
    ad_scope_return_complaint 1 "<li>the comment field was empty"
    return
}

# user has input something, so continue on

db_transaction { 
    # insert into the audit table
    
    db_dml comment_audit_insert "
    insert into general_comments_audit
    (comment_id, 
     user_id, 
     ip_address, 
     audit_entry_time, 
     modified_date, 
     content)
    select 
     :comment_id, 
     :admin_id, 
     '[ns_conn peeraddr]', 
      sysdate, 
      modified_date, 
      content 
    from  general_comments 
    where comment_id = :comment_id" 
    
    db_dml comment_update "
    update general_comments
    set    content    = empty_clob(), 
           html_p     = :html_p, 
           approved_p = :approved_p
    where  comment_id = :comment_id 
    returning content into :1" -clobs [list $content]
} on_error {
    
    # there was some other error with the comment update
    ad_scope_return_error "Error updating comment" "We couldn't update
    your comment. Here is what the database returned: 
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>
    "
    return
}

if { ![empty_string_p return_url] } {
    ad_returnredirect $return_url
} else {
    doc_return  200 text/html "
    [ad_scope_admin_header "Done"]
    [ad_scope_admin_page_title "Done"]
    [ad_scope_admin_context_bar [list "index.tcl" "General Comments"] "Edit"]
    <hr>
    [ad_scope_admin_footer]
    "
}

