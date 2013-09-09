# /admin/links/find.tcl

ad_page_contract {
    Let the site admin look for a related link.

    @param query_string String to search on

    @author Philip Greenspun (philg@mit.edu)
    @creation-date July 18, 1999
    @cvs-id find.tcl,v 3.1.6.5 2000/09/22 01:35:30 kevin Exp
} {
    query_string:notnull
}

set page_content "[ad_admin_header "Related links matching \"$query_string\""]

<h2>Links matching \"$query_string\"</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "Search Results"]

<hr>
 
Matching links:

<ul>
"

set sql_query_string "%[string toupper $query_string]%"

set link_qry "select links.link_title, links.link_description, links.url, links.status,  posting_time,
users.user_id, first_names || ' ' || last_name as name, links.url, sp.page_id, sp.page_title, sp.url_stub
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id
and (upper(links.url) like :sql_query_string
     or
     upper(links.link_title) like :sql_query_string
     or 
     upper(links.link_description) like :sql_query_string)"

set items ""

db_foreach select_links $link_qry {
    set old_url $url
    append items "<li>[util_AnsiDatetoPrettyDate $posting_time]: 
<a href=\"$url\">$link_title</a> "
    if { $status != "live" } {
	append items "(<font color=red>$status</font>)"
    }
    append items "- $link_description 
<br>
--
posted by <a href=\"/admin/users/one?user_id=$user_id\">$name</a> 
on  <a href=\"/admin/static/page-summary?page_id=$page_id\">$url_stub</a>   
&nbsp; 
\[
<a target=working href=\"edit?[export_url_vars url page_id]\">edit</a> |
<a target=working href=\"delete?[export_url_vars url page_id]\">delete</a> |
<a target=working href=\"blacklist?[export_url_vars url page_id]\">blacklist</a>
\]
<p>
"
} if_no_rows {
    append items "no matching links found"
}

db_release_unused_handles

append page_content "
$items

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
