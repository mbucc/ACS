# $Id: for-one-page.tcl,v 3.0 2000/02/06 03:49:33 ron Exp $
set_the_usual_form_variables

# url_stub

set user_id [ad_get_user_id]
set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select page_id, nvl(page_title, url_stub) as page_title, url_stub 
from static_pages where url_stub = '$QQurl_stub'
and accept_links_p = 't'"]

if { $selection == "" } {
    # this page isn't registered in the database 
    # or comments are not allowed so we can't
    # accept links on it or anything
    
    ns_log Notice "Someone grabbed $url_stub but we weren't able to offer for-one-page.tcl because this page isn't registered in the db"
    
    ReturnHeaders
    ns_write "[ad_header "Can not accept links."]

<h3> Can not accept links </h3>

for this page.

<hr>

This <a href =\"/\">[ad_system_name]</a> page is not set up to accept links.

[ad_footer]"

return
}

# there was a link-addable page in the database

set_variables_after_query

ReturnHeaders
ns_write "[ad_header "Related links for $page_title"]

<h2>Related links</h2>

for <a href=\"$url_stub\">$page_title</a>

<hr>
<ul>
"

set selection [ns_db select $db "select links.page_id, links.user_id as poster_user_id, users.first_names || ' ' || users.last_name as user_name, links.link_title, links.link_description, links.url
from static_pages sp, links, users
where sp.page_id = links.page_id
and users.user_id = links.user_id
and links.page_id = $page_id
and status = 'live'
order by posting_time"]

set items ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li><a href=\"$url\">$link_title</a> - $link_description"
    if { $user_id == $poster_user_id} {
	# the user added, so let him/her edit it
	append items "&nbsp;&nbsp;(<A HREF=\"/links/edit.tcl?page_id=$page_id&url=[ns_urlencode $url]\">edit/delete)</a>"
    } else {
	# the user did not add it, link to the community_member page
	append items "&nbsp;&nbsp; <font size=-1>(contributed by <A HREF=\"/shared/community-member.tcl?user_id=$poster_user_id\">$user_name</a>)</font>"
    }
    append items "<p>\n"
}

ns_db releasehandle $db

if [empty_string_p $items] {
    ns_write "There have been no links so far on this page.\n"
} else {
    ns_write "$items"
}

ns_write "

</ul>

<p>
<center>
<a href=\"/links/add.tcl?page_id=$page_id\">Add a link</a>
</center>

[ad_footer]
"

