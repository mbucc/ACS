# /www/admin/referer/search-engine-one-one-month.tcl
#

ad_page_contract {
    one search engine, one month
    @cvs-id search-engine-one-one-month.tcl,v 3.2.2.6 2000/09/22 01:36:00 kevin Exp
    @param query_year
    @param query_month
} {
    search_engine_name:notnull
    query_year:notnull
    query_month:notnull
}


set page_content "[ad_admin_header "$search_engine_name: $query_month/$query_year"]

<h2>$search_engine_name referrals in $query_month/$query_year</h2>

[ad_admin_context_bar [list "" "Referrals"] [list "search-engines" "Search Engine Statistics"] "One Month"]

<hr>

<ul>

"



set first_of_month "$query_year-$query_month-01"

set sql "
select query_string
from query_strings
where search_engine_name = :search_engine_name
and query_date between :first_of_month and add_months(:first_of_month,1)
order by upper(query_string)"

set items ""

db_foreach referer_search_engine_one_month $sql {
    append items "<li>$query_string\n"
}

append page_content $items

append page_content "

</ul>

<i> 

Note: Referrals from public search engines are identified by patterns recorded in the
<code>referer_log_glob_patterns</code> table, maintained at 
<a href=\"/admin/referer/mapping\">/admin/referer/mapping</a>.  The statistics 
on these pages do not include searches done by users locally (i.e., with tools running
on this server).

</i>

[ad_admin_footer]
"


doc_return  200 text/html $page_content
