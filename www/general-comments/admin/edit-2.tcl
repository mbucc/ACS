# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:10:38 carsten Exp $
# File:     /general-comments/admin/edit-2.tcl
# Date:     01/06/99
# author :  philg@mit.edu
# Contact:  philg@mit.edu, tarik@arsdigita.com
# Purpose:  edit comment page
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# comment_id, content, html_p, approved_p
# maybe return_url

ad_scope_error_check 
set db [ns_db gethandle]
set admin_id [general_comments_admin_authorize $db $comment_id]

if { $admin_id == 0 } {
    # we don't know who this is administering, 
    # so we won't be able to audit properly
    ad_returnredirect "/register/"
    return
}

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_scope_return_complaint 1 "<li>the comment field was empty"
    return
}

# user has input something, so continue on

if [catch { 
    ns_db dml $db "begin transaction" 
    # insert into the audit table
    
    ns_db dml $db "
    insert into general_comments_audit
    (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
    select comment_id, $admin_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"
    
    ns_ora clob_dml $db "update general_comments
    set content = empty_clob(), html_p = '$html_p', approved_p = '$approved_p'
    where comment_id = $comment_id returning content into :1" "$content"
    ns_db dml $db "end transaction" 
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

if { [info exists return_url] } {
    ad_returnredirect $return_url
} else {
    ns_return 200 text/html "
    [ad_scope_admin_header "Done" $db]
    [ad_scope_admin_page_title "Done" $db]
    [ad_scope_admin_context_bar [list "index.tcl" "General Comments"] "Edit"]
    <hr>
    [ad_scope_admin_footer]
    "
}

