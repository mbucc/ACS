# /www/admin/searches/by-location.tcl
ad_page_contract {
    location (either a search engine name or a subsection)
    @cvs-id by-location.tcl,v 3.2.2.6 2000/09/22 01:36:03 kevin Exp
} {
    location:notnull
}

set page_content "[ad_admin_header "User searches in $location"]

<h2>User searches in <i>$location</i></h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "One Location"]

<hr>
<ul>"

set sql "select query_date, query_string, 
users.user_id, users.first_names, users.last_name,
decode(subsection, null, search_engine_name, subsection) location, 
decode(n_results, null, '', ' - ' || n_results || ' results') n_results_string,
users.user_id 
from query_strings, users
where query_strings.user_id = users.user_id (+) 
and (subsection = :location or search_engine_name = :location)
order by lower(query_string) asc"

set items ""
db_foreach by_location_select $sql {
    append items "<li>$query_date: <a href=\"by-word?query_string=[ns_urlencode $query_string]\"><b>$query_string</b></a>"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items $n_results_string
}

db_release_unused_handles

append page_content $items

append page_content "</ul>
[ad_admin_footer]
"
doc_return  200 text/html $page_content


