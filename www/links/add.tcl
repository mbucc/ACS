# /links/add.tcl

ad_page_contract {
    Step 1 of 3 in adding a link to a static page

    @param page_id The ID of the page to add a link to

    @creation-date Original Date Unknown
    @author Original Author Unknown
    @cvs-id add.tcl,v 3.4.2.7 2000/09/22 01:38:52 kevin Exp
} {
    page_id:notnull,naturalnum
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_get_user_id]
if {$user_id == 0} {
    ad_returnredirect /register?return_url=[ns_urlencode  /links/add.tcl?[export_url_vars page_id]]
}


db_1row select_info_one_page "select static_pages.page_id, static_pages.url_stub,  nvl(page_title, url_stub) as page_title
from static_pages
where page_id = :page_id"

db_release_unused_handles

set page_content "[ad_header "Add a related link to $page_title" ]

<h2>Add a related link</h2>\n
to <a href=\"$url_stub\">$page_title</a>
<hr>
Add a link that other readers may enjoy.
<p>
<form action=add-2 method=post>\n
<table cellpadding=5>
  <tr><th align=right>URL:</th><td><input type=text name=url size=50 maxlength=300 value=\"http://\"></td></tr>\n

  <tr><th align=right>Title:</th><td><input type=text name=link_title size=50 maxlenghth=100></td></tr>\n
  <tr><th align=right valign=top>Description:</th><td><textarea name=link_description cols=50 rows=5 wrap=soft></textarea></td></tr>\n
  <tr><td></td><td>Would you like to be notified if this link
becomes invalid?<br>
Yes
<input type=radio name=contact_p value=\"t\" checked>
No
<input type=radio name=contact_p value=\"f\"><br>
</td>
</table>
<input type=hidden name=page_id value=\"$page_id\">
<center>
<input type=submit name=submit value=\"Proceed\">
</center>
</form>
[ad_footer]
"

doc_return  200 text/html $page_content
