# $Id: for-one-page.tcl,v 3.0 2000/02/06 03:37:15 ron Exp $
#
# /comments/for-one-page.tcl
#
# by philg@mit.edu back in mid-1998
#
# displays all the comments associated with a particular .html page
# 

set_the_usual_form_variables

# url_stub or page_id

set user_id [ad_get_user_id]
set db [ns_db gethandle]

if { [info exists page_id] && ![empty_string_p $page_id] } {
    set selection [ns_db 0or1row $db "select nvl(page_title,url_stub) as page_title, url_stub 
from static_pages 
where page_id = $page_id
and accept_comments_p = 't'"]
} else {
    set selection [ns_db 0or1row $db "select page_id, nvl(page_title,url_stub) as page_title, url_stub 
from static_pages where url_stub = '$QQurl_stub'
and accept_comments_p = 't'"]
}

if { $selection == "" } {
    # this page isn't registered in the database 
    # or comments are not allowed so we can't
    # accept comments on it or anything

    ns_return 200 text/html "[ad_header "Can not accept comments."]

<h3> Can not accept comments </h3>

for this page.

<hr>

This <a href =\"/\">[ad_system_name]</a> page is not set up to accept comments.

[ad_footer]"
    ns_log Notice "Someone grabbed $url_stub but we weren't able to offer for-one-page.tcl because this page isn't registered in the db"
    return    
}

# there was a commentable page in the database
set_variables_after_query

ReturnHeaders
ns_write "[ad_header "Reader's comments on $page_title"]

<h3>Reader's Comments</h3>

on <a href=\"$url_stub\">$page_title</a>

<hr>"

set selection [ns_db select $db "select comments.comment_id, comments.page_id, comments.user_id as poster_user_id, users.first_names || ' ' || users.last_name as user_name, message, posting_time, html_p
from static_pages sp, comments_not_deleted comments, users
    where sp.page_id = comments.page_id
and comments.user_id = users.user_id
and comments.page_id = $page_id
and comments.comment_type = 'alternative_perspective'
order by posting_time"]

set at_least_one_comment_found_p 0

set comment_bytes ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set at_least_one_comment_found_p 1
    append comment_bytes "<blockquote>
[util_maybe_convert_to_html $message $html_p]
<br><br>
    "
    if { $user_id == $poster_user_id} {
	# the user wrote the message, so let him/her edit it
	append comment_bytes  "-- <A HREF=\"/shared/community-member.tcl?user_id=$poster_user_id\">$user_name</a> 
(<A HREF=\"/comments/persistent-edit.tcl?comment_id=$comment_id\">edit your comment</a>)
"
    } else {
	# the user did not write it, link to the community_member page
	append comment_bytes "-- <A HREF=\"/shared/community-member.tcl?user_id=$poster_user_id\">$user_name</a>"
    }
    append comment_bytes ", [util_AnsiDatetoPrettyDate $posting_time]\n</blockquote>\n"
}

ns_db releasehandle $db
ns_write $comment_bytes

if !$at_least_one_comment_found_p {
	ns_write "<p>There have been no comments so far on this page.\n"
}

ns_write "<center>
<a href=\"/comments/add.tcl?[export_url_vars page_id]\">Add a comment</a>
</center>"
