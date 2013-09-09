# /links/delete.tcl

ad_page_contract {
    Step 1 of 2 in deleting a link from a static page

    @param url The URL of the link to delete
    @param page_id The ID of the page to delete from

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id delete.tcl,v 3.1.6.7 2000/09/22 01:38:52 kevin Exp
} {
    url:notnull
    page_id:notnull,naturalnum
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_verify_and_get_user_id]

db_1row select_page_info "select  nvl(page_title,url_stub) as page_title, url_stub 
from static_pages
where page_id = :page_id"

db_1row select_link_info "select url, link_title, link_description from links where page_id = :page_id and url=:url and user_id=:user_id"

db_release_unused_handles

set page_content "[ad_header "Verify deletion"]
    
<h2>Verify Deletion</h2>
to <a href=\"$url_stub\">$page_title</a>

<hr>
Would you like to delete the following link?
<p>
<a href=\"$url\">$link_title</a> - $link_description
<p>
<table>
<tr><td>
<form action=delete-2 method=post>
[export_form_vars page_id url]
<center>
<input type=submit value=\"Delete Link\" name=submit>
</form>
</td><td>
<form action=\"$url_stub\">
<input type=submit value=\"Cancel\" name=submit>
</form>
</td></tr>
</table>
</center>
</form>
[ad_footer]"

doc_return  200 text/html $page_content
