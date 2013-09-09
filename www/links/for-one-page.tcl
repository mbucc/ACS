# /links/for-one-page.tcl

ad_page_contract {
    Display links for one page

    @param url_stub The location of the static page whose links are being examined

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id for-one-page.tcl,v 3.2.6.8 2000/09/22 01:38:52 kevin Exp
} {
    url_stub:notnull
}

set user_id [ad_get_user_id]

if { [catch {} errmsg] } {
    ad_return_error "Database Unavailable" "
    Sorry, but at the moment the database seems to be offline.
    Please try again later."

    ns_log Warning "db failed in /links/for-one-page.tcl: $errmsg"
    return
}

if {![db_0or1row select_url_info "select page_id, nvl(page_title, url_stub) as page_title, url_stub 
from static_pages where url_stub = :url_stub
and accept_links_p = 't'"]} {
    # this page isn't registered in the database 
    # or comments are not allowed so we can't
    # accept links on it or anything
    
    ns_log Notice "Someone grabbed $url_stub but we weren't able to offer for-one-page.tcl because this page isn't registered in the db"
    
    
    doc_return  200 text/html "[ad_header "Can not accept links."]

<h3> Can not accept links </h3>

for this page.

<hr>

This <a href =\"/\">[ad_system_name]</a> page is not set up to accept links.

[ad_footer]"

return
}

# there was a link-addable page in the database


set page_content "[ad_header "Related links for $page_title"]

<h2>Related links</h2>

for <a href=\"$url_stub\">$page_title</a>

<hr>
<ul>
"

set sql_qry "select links.page_id, links.user_id as poster_user_id, users.first_names || ' ' || users.last_name as user_name, links.link_title, links.link_description, links.url
from static_pages sp, links, users
where sp.page_id = links.page_id
and users.user_id = links.user_id
and links.page_id = :page_id
and status = 'live'
order by posting_time"

set items ""
db_foreach select_page_link_info $sql_qry {
    append items "<li><a href=\"$url\">$link_title</a> - $link_description"
    if { $user_id == $poster_user_id} {
	# the user added, so let him/her edit it
	append items "&nbsp;&nbsp;(<A HREF=\"/links/edit?page_id=$page_id&url=[ns_urlencode $url]\">edit/delete)</a>"
    } else {
	# the user did not add it, link to the community_member page
	append items "&nbsp;&nbsp; <font size=-1>(contributed by <A HREF=\"/shared/community-member?user_id=$poster_user_id\">$user_name</a>)</font>"
    }
    append items "<p>\n"
} if_no_rows {
    append items "There have been no links so far on this page.\n"
}

db_release_unused_handles

append page_content "
$items

</ul>

<p>
<center>
<a href=\"/links/add?page_id=$page_id\">Add a link</a>
</center>

[ad_footer]
"

doc_return 200 text/html $page_content

