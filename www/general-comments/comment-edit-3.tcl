# /general-comments/comment-edit-3.tcl

ad_page_contract {
    @author philg@mit.edu
    @author tarik@mit.edu
    @creation-date 01/21/2000 
    @cvs-id comment-edit-3.tcl,v 3.2.2.2 2000/07/22 22:03:43 berkeley Exp
} {
    {scope ""}
    {group_id ""}
    {on_which_group ""}
    comment_id
    {content:html ""}
    html_p
    item
    {one_line ""}
    {return_url ""}
}

# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}

if { $html_p == "t" && ![empty_string_p [ad_check_for_naughty_html $content]] } {
    ad_return_complaint 1 "<li>[ad_check_for_naughty_html $content]\n"
    return
}


# user has input something, so continue on


set user_id [ad_get_user_id]

db_1row comment_get "select general_comments.user_id as comment_user_id,
                     on_what_id, on_which_table
                     from general_comments
                     where comment_id = :comment_id" -bind [ad_tcl_vars_to_ns_set comment_id]

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id && ![ad_permission_p $module $submodule]} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}

if [catch { 
ad_general_comment_update $comment_id  $content [ns_conn peeraddr] $html_p $one_line } errmsg] {

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

db_release_unused_handles

if { ![empty_string_p $return_url] } { 
    ad_returnredirect $return_url
} else {
    ad_returnredirect "view-one?[export_url_vars comment_id item]"
}
