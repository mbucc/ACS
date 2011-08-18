# $Id: pct-large-table-scans.tcl,v 3.0 2000/02/06 03:25:30 ron Exp $
set db [ns_db gethandle]

set the_query "
select 
  A.Value, B.Value 
from 
  V\$SYSSTAT A, V\$SYSSTAT B 
where 
  A.Name = 'table scans (long tables)' and B.Name = 'table scans (short tables)'"

set scan_info [database_1row_to_tcl_list $db $the_query]

ReturnHeaders
ns_write "

[ad_admin_header "Table Scans"]

<h2>Table Scans</h2>

[ad_admin_context_bar [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Table scans"]

<hr>

If you have a high percentage of large table scans, you want to see if
those tables have been indexed, and whether the queries accessing them
are written in such a way to take advantage of the indicies.

<p>



<blockquote>
<table cellpadding=4>
<tr><th># Large Table Scans</th><th># Small Table Scans</th><th>% Large Scans</th></tr>
<tr>
   <td align=right>[lindex $scan_info 0]</td>
   <td align=right>[lindex $scan_info 1]</td>
   <td align=right>[format %4.2f [expr 100*(double([lindex $scan_info 0])/double([lindex $scan_info 0]+[lindex $scan_info 1]))]]</td>
</tr>
</table>

</blockquote>

<p>
The SQL:
<pre>
$the_query
</pre>
<p>
SQL queries resulting in more than 100 disk reads:

<blockquote>

<table border=2>
<tr><th>User Name</th><th>Disk Reads</th><th>Loads</th><th>Optimizer Cost</th></tr>
"

set disk_read_query "select 
  sql_text, disk_reads, loads, optimizer_cost, parsing_user_id, serializable_aborts, au.username
from 
  v\$sql, all_users au
where 
  disk_reads > 100
and
  parsing_user_id = au.user_id"

set selection [ns_db select $db $disk_read_query]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "
<tr>
  <td align=right>$username (id $parsing_user_id)</td>
  <td align=right>$disk_reads</td>
  <td align=right>$loads</td>
  <td align=right>$optimizer_cost</td>
</tr>
<tr>
   <td colspan=4>SQL: $sql_text</td>
</tr>
"
}

ns_write "
</table>
</blockquote>

The SQL:
<pre>
$disk_read_query
</pre>

[annotated_archive_reference 69]

[ad_admin_footer]
"
