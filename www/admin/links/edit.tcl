# /admin/links/edit.cl

ad_page_contract {
    Edit a link

    @param page_id The ID of the page the link resides on
    @param url The URL of the link to edit

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id edit.tcl,v 3.2.2.6 2000/09/22 01:35:30 kevin Exp
} {
    page_id:notnull,naturalnum
    url:notnull
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

db_1row select_page_info "select static_pages.page_id, static_pages.url_stub,  nvl(page_title, url_stub) as page_title
from static_pages
where page_id = :page_id"

if [catch {db_1row select_link_info "select 
url, link_title, link_description, contact_p, page_id, user_id as link_user_id
from links 
where page_id = :page_id and url=:url"} errmsg] {
    ad_return_error "Link not found" "The link you requested doesn't exist;Oracle has this to say: <pre>$errmsg</pre>"
    return
}

db_release_unused_handles

# For compliance with ol' bt_mergpiece:
set selection [ns_set create]
ns_set put $selection contact_p $contact_p

set page_content "[ad_admin_header "Edit related link on $page_title" ]

<h2>Edit related link</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Edit link"]

<hr>

<ul>
<li>page:  <a href=\"$url_stub\">$url_stub</a>  ($page_title)
</ul>

<form action=edit-2 method=post>
[export_form_vars page_id link_user_id]
<input type=hidden name=old_url value=\"$url\">
<table cellpadding=5>
  <tr><th align=right>URL:</th><td><input type=text name=url size=50 maxlength=300 [export_form_value url]></td></tr>\n
  <tr><th align=right>Title:</th><td><input type=text name=link_title size=50 maxlenghth=100 [export_form_value link_title]></td></tr>\n
  <tr><th align=right valign=top>Description:</th><td><textarea name=link_description cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $link_description]</textarea></td></tr>
  <tr><td></td><td>Notify user if this link
becomes invalid?<br>
Yes
[bt_mergepiece "<input type=radio name=contact_p value=\"t\" checked>
No
<input type=radio name=contact_p value=\"f\">" $selection]<br>
</td>
</table>
<br>
<center>
<input type=submit value=\"Edit Link\">
</center>
</form>

<p>

Note:  If you absolutely hate this link, you can 
<a href=\"delete?[export_url_vars page_id url]\">delete it</a>.

[ad_admin_footer]
"

doc_return  200 text/html $page_content
