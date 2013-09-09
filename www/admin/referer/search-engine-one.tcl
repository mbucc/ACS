# /www/admin/referer/search-engine-one.tcl
#

ad_page_contract {
    @cvs-id search-engine-one.tcl,v 3.3.2.5 2000/09/22 01:36:00 kevin Exp
    @param search_engine
} {
    search_engine_name:notnull
}


set page_content "[ad_admin_header "$search_engine_name"]

<h2>$search_engine_name Referrals to [ad_system_name]</h2>

[ad_admin_context_bar [list "" "Referrals"] [list "search-engines" "Search Engine Statistics"] "One Search Engine"]

<hr>

<blockquote>
<table cellpadding=4>
<tr>
  <th>Month
  <th>Total Referrals
</tr>

"


set sql "
select 
  to_char(query_date,'YYYY') as query_year, 
  to_char(query_date,'MM') as query_month, 
  count(*) as n_searches
from query_strings
where search_engine_name = :search_engine_name
group by to_char(query_date,'YYYY'), to_char(query_date,'MM')
order by query_year, query_month"

set table_rows ""

db_foreach referer_search_engine_one $sql {
    append table_rows "
<tr>
  <td>$query_month/$query_year
  <td align=right><a href=\"search-engine-one-one-month?[export_url_vars search_engine_name query_year query_month]\">$n_searches</a>
</tr>
"
}

append page_content "
$table_rows

</table>
</blockquote>

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
