# $Id: search-engine-one.tcl,v 3.0 2000/02/06 03:27:54 ron Exp $
set_the_usual_form_variables

# search_engine_name 

ReturnHeaders

ns_write "[ad_admin_header "$search_engine_name"]

<h2>$search_engine_name Referrals to [ad_system_name]</h2>

[ad_admin_context_bar [list "index.tcl" "Referrals"] [list "search-engines.tcl" "Search Engine Statistics"] "One Search Engine"]

<hr>

<blockquote>
<table cellpadding=4>
<tr>
  <th>Month
  <th>Total Referrals
</tr>


"

set db [ns_db gethandle]
set selection [ns_db select $db "
select 
  to_char(query_date,'YYYY') as query_year, 
  to_char(query_date,'MM') as query_month, 
  count(*) as n_searches
from query_strings
where search_engine_name = '$QQsearch_engine_name'
group by to_char(query_date,'YYYY'), to_char(query_date,'MM')
order by query_year, query_month"]

set table_rows ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append table_rows "
<tr>
  <td>$query_month/$query_year
  <td align=right><a href=\"search-engine-one-one-month.tcl?[export_url_vars search_engine_name query_year query_month]\">$n_searches</a>
</tr>
"
}

ns_write "
$table_rows

</table>
</blockquote>

<i> 

Note: Referrals from public search engines are identified by patterns recorded in the
<code>referer_log_glob_patterns</code> table, maintained at 
<a href=\"/admin/referer/mapping.tcl\">/admin/referer/mapping.tcl</a>.  The statistics 
on these pages do not include searches done by users locally (i.e., with tools running
on this server).

</i>

[ad_admin_footer]
"
