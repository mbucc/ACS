# $Id: page-summary.tcl,v 3.0 2000/02/06 03:30:24 ron Exp $
#
# /admin/static/page-summary.tcl
#
# by philg@mit.edu in ancient times (mid-1998?)
# 
# display everything that we know about a page,
# list related links and comments,
# display the users who've viewed it
#

set_form_variables

# page_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select page_title, url_stub, draft_p, obsolete_p, accept_comments_p, accept_links_p, inline_comments_p, inline_links_p, index_p, last_updated, users.user_id, users.first_names, users.last_name
from static_pages sp, users
where sp.original_author = users.user_id(+)
and sp.page_id = $page_id "]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$url_stub"]

<h2>$url_stub</h2>

[ad_admin_context_bar [list "index.tcl" "Static Content"] "One Page"]

<hr>
<ul>
"

if ![empty_string_p $page_title] {
    ns_write "<li>Title: \"$page_title\"\n"
}

ns_write "

<li>user page:  <a href=\"$url_stub\">$url_stub</a>
"

if ![empty_string_p $user_id] {
    ns_write "<li>original_author:  <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>\n"
}

if ![empty_string_p $last_updated] {
    ns_write "<li>last updated:  [util_AnsiDatetoPrettyDate $last_updated]\n"
}

ns_write "
<li>Accept Comments?  $accept_comments_p (<a href=\"toggle-accept-comments-p.tcl?[export_url_vars page_id]\">toggle</a>)

<li>Inline Comments?  $inline_comments_p (<a href=\"toggle-inline-comments-p.tcl?[export_url_vars page_id]\">toggle</a>)

<li>Accept Links?  $accept_links_p (<a href=\"toggle-accept-links-p.tcl?[export_url_vars page_id]\">toggle</a>)

<li>Inline Links?  $inline_links_p (<a href=\"toggle-inline-links-p.tcl?[export_url_vars page_id]\">toggle</a>)

<li>Include in Site-wide Index?  $index_p (<a href=\"toggle-index-p.tcl?[export_url_vars page_id]\">toggle</a>)


</ul>
"


set selection [ns_db select $db "select links.link_title, links.link_description, links.url, links.status,  posting_time,
users.user_id, first_names || ' ' || last_name as name 
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id
and links.page_id = $page_id
order by posting_time asc"]

set items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    set old_url $url
    append items "<li>[util_AnsiDatetoPrettyDate $posting_time]: 
<a href=\"$url\">$link_title</a> "
    if { $status != "live" } {
	append items "(<font color=red>$status</font>)"
	set extra_option "\n&nbsp; &nbsp; <a href=\"/admin/links/restore.tcl?[export_url_vars url page_id]\">restore to live status</a>"
    } else {
	set extra_option ""
    }
    append items "- $link_description
<br>
-- posted by <a href=\"users/one.tcl?user_id=$user_id\">$name</a> 
&nbsp; &nbsp;  <a target=working href=\"/admin/links/edit.tcl?[export_url_vars url page_id]\">edit</a> 
&nbsp; &nbsp;  <a target=working href=\"/admin/links/delete.tcl?[export_url_vars url page_id]\">delete</a>
&nbsp; &nbsp;  <a target=working href=\"/admin/links/blacklist.tcl?[export_url_vars url page_id]\">blacklist</a>
$extra_option
<p>
"
}

if ![empty_string_p $items] {
    ns_write "<h3> Related links </h3>
(<a href=\"/admin/links/sweep.tcl?[export_url_vars page_id]\">sweep</a>)
<ul>
$items
</ul>
"
}


# we fill in the page table columns in case the page is not in the database

set selection [ns_db select $db "select comments.page_id, posting_time, comments.comment_id,comments.message,  comments.comment_type, comments.rating, users.user_id, first_names || ' ' || last_name as name, client_file_name, html_p, file_type, original_width, original_height, caption
from static_pages sp, comments_not_deleted comments, users
where sp.page_id (+) = comments.page_id
and users.user_id = comments.user_id
and comments.page_id = $page_id
order by comment_type, posting_time asc"]


set items ""
set last_comment_type ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $last_comment_type != $comment_type } {
	append items "<a name=\"$comment_type\"><h4>$comment_type</h4></a>\n"
	set last_comment_type $comment_type
    }
    append items "<li>[util_AnsiDatetoPrettyDate $posting_time]: "
    if { ![empty_string_p $rating] } {
	append items "$rating -- "
    }
    append items "
[format_static_comment $comment_id $client_file_name $file_type $original_width $original_height $caption $message $html_p]
<br>
-- <a href=\"/admin/users/one.tcl?user_id=$user_id\">$name</a>
   &nbsp; &nbsp; <a href=\"/admin/comments/persistent-edit.tcl?[export_url_vars comment_id]\" target=working>edit</a> &nbsp; &nbsp;  <a href=\"/admin/comments/delete.tcl?[export_url_vars comment_id page_id]\" target=working>delete</a>
<br>
<br>
"
}

if ![empty_string_p $items] {
    ns_write "<H3>Page Comments</H3>
<ul>
$items
</ul>
"
}

set n_deleted_comments [database_to_tcl_string $db "select count(*) 
from comments 
where page_id = $page_id
and deleted_p = 't'"]

if { $n_deleted_comments > 0 } {
    ns_write "There are $n_deleted_comments deleted comments on this page.<p>"
}

set selection [ns_db select $db "select users.user_id, email, first_names || ' ' || last_name as name, page_title, url_stub
from static_pages, user_content_map, users
where static_pages.page_id = user_content_map.page_id
and users.user_id = user_content_map.user_id
and user_content_map.page_id = $page_id
order by last_name"]


ns_write "
Users who
have viewed the page <A HREF=\"$url_stub\">$page_title</a> 
when they were logged into
the site.
<ul>"

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count
    ns_write "<li><A HREF=\"/admin/users/one.tcl?user_id=$user_id\">$name</a> ($email)\n"
}

ns_write "
</ul>
"



ns_write "
[ad_admin_footer]
"
