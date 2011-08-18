# $Id: delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:37 carsten Exp $
# File:     /general-comments/admin/delete-2.tcl
# Date:     01/06/99
# author :  philg@mit.edu
# Contact:  philg@mit.edu, tarik@arsdigita.com
# Purpose:  delete the comment
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
# comment_id, content, html_p, submit, maybe return_url

ad_scope_error_check
set db [ns_db gethandle]
set user_id [general_comments_admin_authorize $db $comment_id]

if { ![info exists return_url] } {
    set return_url "index.tcl"
}

if {[regexp -nocase "cancel" $submit]} {
    ad_returnredirect $return_url
    return
}

if [catch { 
    ns_db dml $db "begin transaction" 
    # insert into the audit table
    ns_db dml $db "insert into general_comments_audit
    (comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
    select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"
    
    ns_db dml $db "
    delete from general_comments where
    comment_id=$comment_id"

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
    " $db
    return
}

ad_returnredirect $return_url

