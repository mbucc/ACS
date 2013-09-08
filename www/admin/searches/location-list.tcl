# /www/admin/searches/location-list.tcl
ad_page_contract {
    @cvs-id location-list.tcl,v 3.2.2.5 2000/09/22 01:36:05 kevin Exp
} {
}

set page_content "[ad_admin_header "User Searches - locations"]

<h2>User Searches - locations</h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "Distinct Locations"]

<hr>

Search query strings come from two sources.  First, we capture strings
entered on the site in local search engines, e.g., when a user
searches the classified ads or a bboard forum.  Second, we are
sometimes able to harvest query strings from HTTP referer headers when
a user visits [ad_system_name] from a public Internet search engine (e.g., 
AltaVista).

<h3>[ad_system_name] subsections</h3>
<ul>
"

set sql "select distinct subsection
from query_strings
where subsection is not null
order by upper(subsection)"

db_foreach location_search_select $sql {
    append page_content "<li><a href=\"by-location?location=[ns_urlencode $subsection]\">$subsection</a>"
}

append page_content "</ul>
<h3>Search engines</h3>
<ul>"

set sql "select distinct search_engine_name
from query_strings
where search_engine_name is not null
order by upper(search_engine_name)"

db_foreach search_engine_select $sql {
    append page_content "<li><a href=\"by-location?location=[ns_urlencode $search_engine_name]\">$search_engine_name</a>"
}

db_release_unused_handles

append page_content "
</ul>

To add search engines, visit <a href=\"/admin/referer/mapping\">the URL lumping section of the 
referer logging admin pages</a>.

[ad_admin_footer]
"

doc_return  200 text/html $page_content

