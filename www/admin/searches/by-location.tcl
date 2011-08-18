# $Id: by-location.tcl,v 3.0 2000/02/06 03:28:13 ron Exp $
set_the_usual_form_variables

# location (either a search engine name or a subsection)

ReturnHeaders

ns_write "[ad_admin_header "User searches in $location"]

<h2>User searches in <i>$location</i></h2>

[ad_admin_context_bar [list "index.tcl" "User Searches"] "One Location"]


<hr>
<ul>"


set db [ns_db gethandle]

set selection [ns_db select $db "select query_date, query_string, 
users.user_id, users.first_names, users.last_name,
decode(subsection, null, search_engine_name, subsection) location, 
decode(n_results, null, '', ' - ' || n_results || ' results') n_results_string,
users.user_id 
from query_strings, users
where query_strings.user_id = users.user_id (+) 
and (subsection = '$QQlocation' or search_engine_name='$QQlocation')
order by lower(query_string) asc"]

set items ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append items "<li>$query_date: <a href=\"by-word.tcl?query_string=[ns_urlencode $query_string]\"><b>$query_string</b></a>"
    if ![empty_string_p $user_id] { 
	append items " <a href=\"/admin/users/one.tcl?user_id=$user_id\">$first_names $last_name</a> "
    }
    append items $n_results_string
}

ns_write $items

ns_write "</ul>
[ad_admin_footer]
"
