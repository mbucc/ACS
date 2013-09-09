# /www/admin/searches/results-none.tcl
ad_page_contract {
    @cvs-id results-none.tcl,v 3.1.6.5 2000/09/22 01:36:05 kevin Exp
} {
}

set page_content "[ad_admin_header "User searches with 0 results"]

<h2>User searches with 0 results</h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "Failures"]

<hr>
<ul>
"

set sql "select query_string, query_date,
users.user_id, users.first_names, users.last_name,
decode(subsection, null, search_engine_name, subsection) location, 
users.user_id 
from query_strings, users
where query_strings.user_id = users.user_id (+) 
and n_results = 0 
and subsection is not null
order by lower(query_string) asc"

set items ""
db_foreach no_results_select $sql {
    append items "<li>$query_date:
<a href=\"by-word?query_string=[ns_urlencode $query_string]\"><b>$query_string</b></a> 
<a href=\"by-location?location=[ns_urlencode $location]\">($location)</a>
"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items "\n"
}

db_release_unused_handles

append page_content $items

append page_content "</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content

