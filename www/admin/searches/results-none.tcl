# $Id: results-none.tcl,v 3.0 2000/02/06 03:28:23 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "User searches with 0 results"]

<h2>User searches with 0 results</h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "Failures"]

<hr>
<ul>
"

set db [ns_db gethandle]

set selection [ns_db select $db "select query_string, query_date,
users.user_id, users.first_names, users.last_name,
decode(subsection, null, search_engine_name, subsection) location, 
users.user_id 
from query_strings, users
where query_strings.user_id = users.user_id (+) 
and n_results = 0 
and subsection is not null
order by lower(query_string) asc"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li>$query_date:
<a href=\"by-word.tcl?query_string=[ns_urlencode $query_string]\"><b>$query_string</b></a> 
<a href=\"by-location.tcl?location=[ns_urlencode $location]\">($location)</a>
"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items "\n"
}

ns_write $items

ns_write "</ul>
[ad_admin_footer]
"

