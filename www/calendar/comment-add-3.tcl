# $Id: comment-add-3.tcl,v 3.1.2.1 2000/04/28 15:09:47 carsten Exp $
# File:     /calendar/comment-add-3.tcl
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
# calendar_id, content, comment_id, content, html_p
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope all group_member registered

# check for bad input
if { ![info exists content] || [empty_string_p $content] } {
    ad_scope_return_complaint 1 "<li>the comment field was empty" $db
    return
}

# user has input something, so continue on

# assign necessary data for insert
set user_id [ad_verify_and_get_user_id]
set originating_ip [ns_conn peeraddr]

if { [ad_parameter CommentApprovalPolicy calendar] == "open"} {
    set approved_p "t"
} else {
    set approved_p "f"
}

set one_line_item_desc [database_to_tcl_string $db "select title from calendar where calendar_id = $calendar_id"]


if [catch { 
    ad_general_comment_add $db $comment_id "calendar" $calendar_id $one_line_item_desc $content $user_id $originating_ip $approved_p $html_p ""
} errmsg] {
    # Oracle choked on the insert
    if { [database_to_tcl_string $db "select count(*) from general_comments where comment_id = $comment_id"] == 0 } {
	# there was an error with comment insert other than a duplication
	ad_scope_return_error "Error in inserting comment" "We were unable to insert your comment in the database.  Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>" $db
	return
    }
}

# either we were successful in doing the insert or the user hit submit
# twice and we don't really care

ad_returnredirect "item.tcl?[export_url_scope_vars calendar_id]"
