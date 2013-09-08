# /www/admin/searches/recent.tcl
ad_page_contract {
    @cvs-id recent.tcl,v 3.2.2.5 2000/09/22 01:36:05 kevin Exp
} {
    num_days:naturalnum,notnull
}

set page_content "[ad_admin_header "Searches in the last $num_days days"]

<h2>Searches in the last $num_days days</h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "Last $num_days days"]

<hr>
<ul>"

set sql "select query_date, query_string,
users.user_id, users.first_names, users.last_name,
decode(subsection, null, search_engine_name, subsection) location, 
decode(n_results, null, '', ' - ' || n_results || ' results') n_results_string,
users.user_id 
from query_strings, users
where query_strings.user_id = users.user_id (+) 
and query_date > (SYSDATE - :num_days)
order by query_date desc"

set items ""
db_foreach past_numdays_select $sql {
    append items "<li>$query_date: 
<a href=\"by-word?query_string=[ns_urlencode $query_string]\"><b>$query_string</b></a> 
<a href=\"by-location?location=[ns_urlencode $location]\">($location)</a>
"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items "$n_results_string\n"
}

db_release_unused_handles

append page_content $items 

append page_content "</ul>
[ad_admin_footer]
"

doc_return  200 text/html $page_content
