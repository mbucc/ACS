# /links/edit.tcl

ad_page_contract {
    Step 1 of 3 in editing a static page link

    @param page_id The ID of the page we're editing from
    @param url The URL to edit

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id edit.tcl,v 3.2.2.7 2000/09/22 01:38:52 kevin Exp
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

db_1row select_link_info "select 
 url, link_title, link_description, contact_p, page_id, user_id as link_user_id
 from links 
 where page_id = :page_id and url=:url"

db_release_unused_handles

# For compliance with ol' bt_mergpiece:
set selection [ns_set create]
ns_set put $selection contact_p $contact_p

set user_id [ad_verify_and_get_user_id]

if { $link_user_id != $user_id } {
    ad_return_error "Unauthorized" "You are not allowed to edit a link you did not enter"
    return
}

set page_content "[ad_header "Edit related link on $page_title" ]

<h2>Edit related link</h2>
on <a href=\"$url_stub\">$page_title</a>
<hr>
<form action=edit-2 method=post>
[export_form_vars page_id]
<input type=hidden name=old_url value=\"$url\">
<table cellpadding=5>
  <tr><th align=right>URL:</th><td><input type=text name=url size=50 maxlength=300 [export_form_value url]></td></tr>\n
  <tr><th align=right>Title:</th><td><input type=text name=link_title size=50 maxlenghth=100 [export_form_value link_title]></td></tr>\n
  <tr><th align=right valign=top>Description:</th><td><textarea name=link_description cols=50 rows=5 wrap=soft>[philg_quote_double_quotes $link_description]</textarea></td></tr>
  <tr><td></td><td>Would you like to be notified if this link
becomes invalid?<br>
Yes
[bt_mergepiece "<input type=radio name=contact_p value=\"t\" checked>
No
<input type=radio name=contact_p value=\"f\">" $selection]<br>
</td>
</table>
<center>
<table>
<tr><td>
<input type=submit name=submit value=\"Edit Link\">
</form>
</td><td>
<form action=delete method=post>
[export_form_vars page_id url]
<input type=submit name=submit value=\"Delete Link\">
</form>
</td></tr>
</table>
</center>
[ad_footer]
"

doc_return  200 text/html $page_content

