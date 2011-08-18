# $Id: view-one.tcl,v 3.0 2000/02/06 03:44:04 ron Exp $
# File:     /general-comments/view-one.tcl
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

set_form_variables
# comment_id, return_url
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

# check for the user cookie
set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration

set db [ns_db gethandle]

set selection [ns_db 1row $db "select comment_id, content, general_comments.html_p as comment_html_p, general_comments.user_id as comment_user_id, client_file_name, file_type, original_width, original_height, caption, one_line,
first_names || ' ' || last_name as commenter_name
from general_comments, users
where comment_id = $comment_id
and users.user_id = general_comments.user_id"]
set_variables_after_query

ns_db releasehandle $db 

append return_string "[ad_header "Edit comment on $item" ]

<h2>Comment on $item</h2>

[ad_context_bar_ws  [list "$return_url" $item]  "Comment"]

<hr>

<blockquote>\n[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $comment_html_p $one_line]"

# if the user posted the comment, they are allowed to edit it
if {$user_id == $comment_user_id} {
    append return_string "<br><br>-- you <A HREF=\"/general-comments/comment-edit.tcl?[export_url_vars comment_id on_which_table on_what_id item module return_url submodule]\">(edit your comment)</a>"
} else {
    append return_string "<br><br>-- <a href=\"/shared/community-member.tcl?user_id=$comment_user_id\">$commenter_name</a>"
}

append return_string "</blockquote>"

ns_return 200 text/html "

$return_string

[ad_footer]"

