# /admin/links/recent.tcl

ad_page_contract {
    Examine the most recent links

    @param num_days How many days 'recent' means

    @author Original Author Unknown
    @creation-date Original Date Unknown
    @cvs-id recent.tcl,v 3.2.2.5 2000/09/22 01:35:31 kevin Exp
} {
    num_days:notnull
}

if { $num_days == "all" } {
    set title "All related links"
    set subtitle ""
    set posting_time_clause "" 
} else {
    set title "Related links"
    set subtitle "added over the past $num_days day(s)"
    set posting_time_clause "\nand posting_time > (SYSDATE - $num_days)" 
}

set page_content "[ad_admin_header $title]

<h2>$title</h2>

[ad_admin_context_bar [list "index.tcl" "Links"] "List"]

<hr>
 
$subtitle 

<ul>
"

set link_qry "select links.link_title, links.link_description, links.url, links.status,  posting_time,
users.user_id, first_names || ' ' || last_name as name, links.url, sp.page_id, sp.page_title, sp.url_stub
from static_pages sp, links, users
where sp.page_id (+) = links.page_id
and users.user_id = links.user_id $posting_time_clause
order by posting_time desc"

set items ""

db_foreach select_links_by_recency $link_qry {
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
}

db_release_unused_handles

append page_content "
$items

</ul>

[ad_admin_footer]
"

doc_return  200 text/html $page_content
