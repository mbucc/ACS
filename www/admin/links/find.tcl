# $Id: find.tcl,v 3.0 2000/02/06 03:24:41 ron Exp $
# find.tcl
# 
# by philg@mit.edu on July 18, 1999
# 
# let the site admin look for a related link
# 

set_the_usual_form_variables

# query_string

ReturnHeaders

ns_write "[ad_admin_header "Related links matching \"$query_string\""]

<h2>Links matching \"$query_string\"</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Search Results"]

<hr>
 
Matching links:

<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select links.link_title, links.link_description, links.url, links.status,  posting_time,
users.user_id, first_names || ' ' || last_name as name, links.url, sp.page_id, sp.page_title, sp.url_stub
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id
and (upper(links.url) like upper('%$QQquery_string%')
     or
     upper(links.link_title) like upper('%$QQquery_string%')
     or 
     upper(links.link_description) like upper('%$QQquery_string%'))"]

set items ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set old_url $url
    append items "<li>[util_AnsiDatetoPrettyDate $posting_time]: 
<a href=\"$url\">$link_title</a> "
    if { $status != "live" } {
	append items "(<font color=red>$status</font>)"
    }
    append items "- $link_description 
<br>
--
posted by <a href=\"/admin/users/one.tcl?user_id=$user_id\">$name</a> 
on  <a href=\"/admin/static/page-summary.tcl?page_id=$page_id\">$url_stub</a>   
&nbsp; 
\[
<a target=working href=\"edit.tcl?[export_url_vars url page_id]\">edit</a> |
<a target=working href=\"delete.tcl?[export_url_vars url page_id]\">delete</a> |
<a target=working href=\"blacklist.tcl?[export_url_vars url page_id]\">blacklist</a>
\]
<p>
"
}
 
if ![empty_string_p $items] {
    ns_write $items
} else {
    ns_write "no matching links found"
}

ns_write "
</ul>

[ad_admin_footer]
"
