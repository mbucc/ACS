# /links/delete-2.tcl

ad_page_contract {
    Step 2 of 2 in deleting a link from a static page

    @param page_id The ID of the page to remove the link from
    @param url The URL of the link to remove

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id delete-2.tcl,v 3.1.2.7 2000/09/22 01:38:52 kevin Exp
} {
    page_id:notnull,naturalnum
    url:notnull
}


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

db_1row select_page_info "select url_stub, nvl(page_title, url_stub) as page_title
from static_pages
where static_pages.page_id = :page_id"

set user_id [ad_get_user_id]
db_dml delete_link "delete from links where page_id=:page_id and url=:url and user_id = :user_id"

db_release_unused_handles

set page_content "[ad_header "Link Deleted"]
    
<h2>Link Deleted</h2>

from <a href=\"$url_stub\">$page_title</a>
<hr>
<p>
Return to  <a href=\"$url_stub\">$page_title</a>
<p>
[ad_footer]"

doc_return  200 text/html $page_content
