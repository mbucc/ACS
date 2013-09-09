ad_page_contract {
    displays all the comments associated with a particular .html page

    @author philg@mit.edu
    @creation-date mid-1998
    @param page_id
    @param url_stub
    @cvs-id for-one-page.tcl,v 3.3.2.5 2000/09/22 01:37:16 kevin Exp
} {
    {url_stub ""}
    {page_id:integer,optional ""}
}


set user_id [ad_get_user_id]

if { [catch {} errmsg] } {
    ad_return_error "Database Unavailable" "
    Sorry, but at the moment the database seems to be offline.
    Please try again later."

    ns_log Warning "ns_db failed in /comments/for-one-page.tcl: $errmsg"
    return
}

if { ![empty_string_p $page_id] } {
    set num_rows [db_0or1row comments_for_one_page_get "
    select nvl(page_title,url_stub) as page_title, url_stub 
    from static_pages 
    where page_id = :page_id
    and accept_comments_p = 't'"]
} else {
    set num_rows [db_0or1row comments_for_one_page_get_2 "
    select page_id, nvl(page_title,url_stub) as page_title, url_stub 
    from static_pages where url_stub = :url_stub
    and accept_comments_p = 't'" ]
}

if { $num_rows==0 } {
    # this page isn't registered in the database 
    # or comments are not allowed so we can't
    # accept comments on it or anything

    doc_return  200 text/html "[ad_header "Can not accept comments."]

<h3> Can not accept comments </h3>

for this page.

<hr>

This <a href =\"/\">[ad_system_name]</a> page is not set up to accept comments.

[ad_footer]"
    ns_log Notice "Someone grabbed $url_stub but we weren't able to offer for-one-page.tcl because this page isn't registered in the db"
    return    
}

# there was a commentable page in the database

set html "[ad_header "Reader's comments on $page_title"]

<h3>Reader's Comments</h3>

on <a href=\"$url_stub\">$page_title</a>

<hr>"

set sql "select comments.comment_id, comments.page_id, comments.user_id as poster_user_id, users.first_names || ' ' || users.last_name as user_name, message, posting_time, html_p
from static_pages sp, comments_not_deleted comments, users
    where sp.page_id = comments.page_id
and comments.user_id = users.user_id
and comments.page_id = :page_id
and comments.comment_type = 'alternative_perspective'
order by posting_time"

set at_least_one_comment_found_p 0

set comment_bytes ""
db_foreach comments_list $sql  {
    set at_least_one_comment_found_p 1
    append comment_bytes "<blockquote>
[util_maybe_convert_to_html $message $html_p]
<br><br>
    "
    if { $user_id == $poster_user_id} {
	# the user wrote the message, so let him/her edit it
	append comment_bytes  "-- <A HREF=\"/shared/community-member?user_id=$poster_user_id\">$user_name</a> 
(<A HREF=\"/comments/persistent-edit?comment_id=$comment_id\">edit your comment</a>)
"
    } else {
	# the user did not write it, link to the community_member page
	append comment_bytes "-- <A HREF=\"/shared/community-member?user_id=$poster_user_id\">$user_name</a>"
    }
    append comment_bytes ", [util_AnsiDatetoPrettyDate $posting_time]\n</blockquote>\n"
}

append html $comment_bytes

if !$at_least_one_comment_found_p {
	append html "<p>There have been no comments so far on this page.\n"
}

append html "<center>
<a href=\"/comments/add?[export_url_vars page_id]\">Add a comment</a>
</center>"

doc_return  200 text/html $html

