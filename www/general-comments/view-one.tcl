# /general-comments/view-one.tcl

ad_page_contract {
    View one comment.
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000
    @cvs-id view-one.tcl,v 3.2.2.5 2000/09/22 01:38:02 kevin Exp
} {
    {comment_id:integer}
    {item}
    {return_url ""}
    {scope ""}
    {group_id ""}
    {on_which_group ""}
    {on_what_id ""}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}


# check for the user cookie
set user_id [ad_get_user_id]
ad_maybe_redirect_for_registration


db_1row comment_get "select comment_id, content, general_comments.html_p as comment_html_p, general_comments.user_id as comment_user_id, client_file_name, file_type, original_width, original_height, caption, one_line,
first_names || ' ' || last_name as commenter_name
from general_comments, users
where comment_id = :comment_id
and users.user_id = general_comments.user_id" -bind [ad_tcl_vars_to_ns_set comment_id]

db_release_unused_handles 

append return_string "[ad_header "Edit comment on $item" ]

<h2>Comment on $item</h2>
"

if { ![empty_string_p $return_url] } {
    append return_string "
    [ad_context_bar_ws  [list "$return_url" $item]  "Comment"]
    "
} else {
    append return_string "
    [ad_context_bar_ws  "Comment"]
    "
}

append return_string "
<hr>

<blockquote>\n[format_general_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $content $comment_html_p $one_line]"

# if the user posted the comment, they are allowed to edit it
if {$user_id == $comment_user_id} {
    if { ![empty_string_p $return_url] } {
	# check whether return_url was provided; we don't want to pass return_url if it wasn't provided
	append return_string "<br><br>-- you <A HREF=\"/general-comments/comment-edit?[export_url_vars comment_id on_which_table on_what_id item module return_url submodule]\">(edit your comment)</a>"
    } else {
	append return_string "<br><br>-- you <A HREF=\"/general-comments/comment-edit?[export_url_vars comment_id on_which_table on_what_id item module submodule]\">(edit your comment)</a>"
    }
} else {
    append return_string "<br><br>-- <a href=\"/shared/community-member?user_id=$comment_user_id\">$commenter_name</a>"
}

append return_string "</blockquote>"

doc_return  200 text/html "

$return_string

[ad_footer]"

