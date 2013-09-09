# /www/admin/referer/search-engines.tcl
#

ad_page_contract {
    List referal summary by search engine.
    @cvs-id Id: search-engines.tcl,v 3.2.2.2 2000/07/13 06:27:03 paul Exp $
} {
}


set page_content "[ad_admin_header "Search Engine Referrals to [ad_system_name]"]

<h2>Search Engine Referrals to [ad_system_name]</h2>

[ad_admin_context_bar [list "" "Referrals"] "Search Engine Statistics"]

<hr>

<blockquote>
<table cellpadding=4>
<tr>
  <th>Search Engine
  <th>Total Referrals
  <th>From
  <th>To
</tr>

"


set sql "
select 
  search_engine_name, 
  count(*) as n_searches, 
  min(query_date) as earliest, 
  max(query_date) as latest
from query_strings
where search_engine_name is not null
group by search_engine_name
order by n_searches desc"

set table_rows ""

db_foreach referer_search_engine_summary $sql {
    append table_rows "
<tr>
  <td>$search_engine_name
  <td align=right><a href=\"search-engine-one?[export_url_vars search_engine_name]\">$n_searches</a>
  <td>[util_AnsiDatetoPrettyDate $earliest]
  <td>[util_AnsiDatetoPrettyDate $latest]
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
