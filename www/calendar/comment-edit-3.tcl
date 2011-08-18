# $Id: comment-edit-3.tcl,v 3.1.2.1 2000/04/28 15:09:47 carsten Exp $
# File:     /calendar/comment-edit-3.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables 0
# comment_id, content, html_p
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered


# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_scope_return_complaint 1 "<li>the comment field was empty" $db
    return
}

# user has input something, so continue on

set user_id [ad_verify_and_get_user_id]

set selection [ns_db 1row $db "select calendar_id, general_comments.user_id as comment_user_id
from calendar, general_comments
where comment_id = $comment_id
and calendar.calendar_id = general_comments.on_what_id"]
set_variables_after_query


# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_scope_return_complaint 1 "<li>You can not edit this entry because you did not post it" $db
    return
}

if [catch { ns_db dml $db "begin transaction" 
            # insert into the audit table
            ns_db dml $db "insert into general_comments_audit
(comment_id, user_id, ip_address, audit_entry_time, modified_date, content)
select comment_id, user_id, '[ns_conn peeraddr]', sysdate, modified_date, content from general_comments where comment_id = $comment_id"
            ns_ora clob_dml $db "update general_comments
set content = empty_clob(), html_p = '$html_p'
where comment_id = $comment_id returning content into :1" "$content"
            ns_db dml $db "end transaction" } errmsg] {

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

ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"
