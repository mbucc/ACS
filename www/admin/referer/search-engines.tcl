# $Id: search-engines.tcl,v 3.0 2000/02/06 03:27:55 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Search Engine Referrals to [ad_system_name]"]

<h2>Search Engine Referrals to [ad_system_name]</h2>

[ad_admin_context_bar [list "index.tcl" "Referrals"] "Search Engine Statistics"]

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

set db [ns_db gethandle]
set selection [ns_db select $db "
select 
  search_engine_name, 
  count(*) as n_searches, 
  min(query_date) as earliest, 
  max(query_date) as latest
from query_strings
where search_engine_name is not null
group by search_engine_name
order by n_searches desc"]

set table_rows ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append table_rows "
<tr>
  <td>$search_engine_name
  <td align=right><a href=\"search-engine-one.tcl?[export_url_vars search_engine_name]\">$n_searches</a>
  <td>[util_AnsiDatetoPrettyDate $earliest]
  <td>[util_AnsiDatetoPrettyDate $latest]
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
