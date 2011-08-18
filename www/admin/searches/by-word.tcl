# $Id: by-word.tcl,v 3.0 2000/02/06 03:28:17 ron Exp $
set_the_usual_form_variables

# query_string

ReturnHeaders

ns_write "[ad_admin_header "Searches for the word $query_string"]

<h2>Searches for the word <i>$query_string</i></h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "One Query"]

<hr>
<ul>"

set db [ns_db gethandle]

set selection [ns_db select $db "
select 
 query_date, 
 users.user_id, users.first_names, users.last_name,
 decode(subsection, null, search_engine_name, subsection) location, 
 decode(n_results, null, '', n_results || ' results') n_results_string
from query_strings, users
where query_strings.user_id = users.user_id (+)
and query_strings.query_string = '$QQquery_string'
order by query_date desc"]

set items "" 
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li>$query_date: 
<a href=\"by-location.tcl?location=[ns_urlencode $location]\">$location</a>
"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items $n_results_string
}

ns_write $items

ns_write "</ul>
[ad_admin_footer]
"
