# $Id: search-engine-one-one-month.tcl,v 3.0 2000/02/06 03:27:53 ron Exp $
# one search engine, one month

set_the_usual_form_variables

# search_engine_name, query_year, query_month

ReturnHeaders

ns_write "[ad_admin_header "$search_engine_name: $query_month/$query_year"]

<h2>$search_engine_name referrals in $query_month/$query_year</h2>

[ad_admin_context_bar [list "index.tcl" "Referrals"] [list "search-engines.tcl" "Search Engine Statistics"] "One Month"]

<hr>

<ul>

"

set db [ns_db gethandle]

set first_of_month "$query_year-$query_month-01"

set selection [ns_db select $db "
select query_string
from query_strings
where search_engine_name = '$QQsearch_engine_name'
and query_date between '$first_of_month' and add_months('$first_of_month',1)
order by upper(query_string)"]

set items ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append items "<li>$query_string\n"
}

ns_write $items

ns_write "

</ul>

<i> 

Note: Referrals from public search engines are identified by patterns recorded in the
<code>referer_log_glob_patterns</code> table, maintained at 
<a href=\"/admin/referer/mapping.tcl\">/admin/referer/mapping.tcl</a>.  The statistics 
on these pages do not include searches done by users locally (i.e., with tools running
on this server).

</i>

[ad_admin_footer]
"
