# $Id: edit.tcl,v 3.0 2000/02/06 03:24:40 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# page_id, url

set db [ns_db gethandle]

set selection [ns_db 1row $db "select static_pages.page_id, static_pages.url_stub,  nvl(page_title, url_stub) as page_title
from static_pages
where page_id = $page_id"]
set_variables_after_query

set selection [ns_db 1row $db "select 
url, link_title, link_description, contact_p, page_id, user_id as link_user_id
from links 
where page_id = $page_id and url='$QQurl'"]
set_variables_after_query

ns_db releasehandle $db

ns_return 200 text/html "[ad_admin_header "Edit related link on $page_title" ]

<h2>Edit related link</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Edit link"]

<hr>

<ul>
<li>page:  <a href=\"$url_stub\">$url_stub</a>  ($page_title)
</ul>


<form action=edit-2.tcl method=post>
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
<a href=\"delete.tcl?[export_url_vars page_id url]\">delete it</a>.

[ad_admin_footer]
"

