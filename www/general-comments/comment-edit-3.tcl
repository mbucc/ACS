# $Id: comment-edit-3.tcl,v 3.0.4.1 2000/04/28 15:10:37 carsten Exp $
# File:     /general-comments/comment-edit-3.tcl
# Date:     01/21/2000
# Contact:  philg@mit.edu, tarik@mit.edu
# Purpose:  
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
# comment_id, content, html_p, on_which_table, on_what_id, return_url, item
# maybe one_line

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $content]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $content]\n"
    return
}

if {![info exists one_line]} {
    set one_line ""
}

# user has input something, so continue on

set db [ns_db gethandle]
set user_id [ad_get_user_id]

set selection [ns_db 1row $db "select  general_comments.user_id 
as comment_user_id
from general_comments
where comment_id = $comment_id"]
set_variables_after_query

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id && ![ad_permission_p $db $module $submodule]} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}

if [catch { 
ad_general_comment_update $db $comment_id  $content [ns_conn peeraddr] $html_p $one_line } errmsg] {

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

ad_returnredirect $return_url
