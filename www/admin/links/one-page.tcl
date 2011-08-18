# $Id: one-page.tcl,v 3.0 2000/02/06 03:24:46 ron Exp $
set_form_variables

# page_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select page_title, url_stub, draft_p, obsolete_p, accept_comments_p, accept_links_p, inline_comments_p, inline_links_p, last_updated, users.user_id, users.first_names, users.last_name
from static_pages sp, users
where sp.original_author = users.user_id(+)
and sp.page_id = $page_id "]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$url_stub"]

<h2>Related links to $url_stub </h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "One Page"]

<hr>

<ul>
<li>user page:  <a href=\"$url_stub\">$url_stub</a>
<li>admin summary: <a href=\"/admin/static/page-summary.tcl?[export_url_vars page_id]\">full page summary</a>

"

if ![empty_string_p $user_id] {
    ns_write "<li>original_author:  <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a>\n"
}

if ![empty_string_p $last_updated] {
    ns_write "<li>last updated:  [util_AnsiDatetoPrettyDate $last_updated]\n"
}

ns_write "

<p>

<li>Sweep:  <a href=\"sweep.tcl?page_id=$page_id\">have the robot check the links below</a>
</ul>

<h3>The Links</h3>

<ul>

"


set selection [ns_db select $db "select links.link_title, links.link_description, links.url, links.status,  posting_time,
users.user_id, first_names || ' ' || last_name as name 
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id
and links.page_id = $page_id
order by posting_time desc"]

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
&nbsp; &nbsp;  
<a target=working href=\"/admin/links/edit.tcl?[export_url_vars url page_id]\">edit</a> 
&nbsp; &nbsp;  
<a target=working href=\"/admin/links/delete.tcl?[export_url_vars url page_id]\">delete</a>
&nbsp; &nbsp;  
<a target=working href=\"/admin/links/blacklist.tcl?[export_url_vars url page_id]\">blacklist</a>
$extra_option
<p>
"
}

ns_write " 
$items
</ul>

[ad_admin_footer]
"
