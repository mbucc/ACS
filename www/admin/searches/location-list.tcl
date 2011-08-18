# $Id: location-list.tcl,v 3.0 2000/02/06 03:28:19 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "User Searches - locations"]

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

set db [ns_db gethandle]

set selection [ns_db select $db "select distinct subsection
from query_strings
where subsection is not null
order by upper(subsection)"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"by-location.tcl?location=[ns_urlencode $subsection]\">$subsection</a>"
}

ns_write "</ul>
<h3>Search engines</h3>
<ul>"

set selection [ns_db select $db "select distinct search_engine_name
from query_strings
where search_engine_name is not null
order by upper(search_engine_name)"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"by-location.tcl?location=[ns_urlencode $search_engine_name]\">$search_engine_name</a>"
}

ns_write "
</ul>

To add search engines, visit <a href=\"/admin/referer/mapping.tcl\">the URL lumping section of the 
referer logging admin pages</a>.

[ad_admin_footer]
"
