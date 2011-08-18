# $Id: data-block-waits.tcl,v 3.0 2000/02/06 03:25:27 ron Exp $
set db [cassandracle_gethandle]

set the_query "select
  A.Value, B.Count from V\$PARAMETER A, V\$WAITSTAT B
where 
  (A.Name = 'db_writers' or A.Name = 'dbwr_io_slaves')
  and B.Class = 'data block'"

set wait_info [database_1row_to_tcl_list $db $the_query]

ReturnHeaders
ns_write "

[ad_admin_header "Data Block Waits"]

<h2>Data Block Waits</h2>

[ad_admin_context_bar [list "/admin/" "Admin Home"] [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Data Block Waits"]

<hr>

<blockquote>

<table cellpadding=4>
<tr><th>Number of DBWR process</th><th>Cumulative Data Block Waits</th></tr>
<tr>
  <td align=right>[lindex $wait_info 0]</td>
  <td align=right>[lindex $wait_info 1]</td>
</tr>
</table>

</blockquote>

Data Block Waits are cumulative since database startup.  If the number
is excessive, you can increase the number of DBWR processes.

<p>
The SQL:
<pre>
$the_query
</pre>

[annotated_archive_reference 78]

[ad_admin_footer]
"
