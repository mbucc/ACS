# $Id: hit-ratio.tcl,v 3.0 2000/02/06 03:25:33 ron Exp $
ReturnHeaders

ns_write "

[ad_admin_header "Hit ratio"]

<h2>Hit ratio</h2>

[ad_admin_context_bar [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Hit ratio"]

<hr>

The hit ratio is the percentage of block gets that were satisfied from
the block cache in the SGA (RAM).  The number of physical reads shows
the times that Oracle had to go to disk to get table information.  Hit
ratio should be at least 98% for anything except a data warehouse.


<blockquote>
<table>
<tr><th>Username</th><th>Consistent Gets</th><th>Block Gets</th><th>Physical Reads</th><th>Hit Ratio</th></tr>
"
set db [ns_db gethandle]

set the_query "
select 
  username, consistent_gets, block_gets, physical_reads 
from 
  V\$SESSION, V\$SESS_IO 
where
  V\$SESSION.SID = V\$SESS_IO.SID and (Consistent_gets + block_gets > 0) and Username is not null"

set object_ownership_info [database_to_tcl_list_list $db $the_query]

if {[llength $object_ownership_info]==0} {
    ns_write "<tr><td>No objects found!</td></tr>"
} else {
    foreach row $object_ownership_info {
	ns_write "<tr><td>[lindex $row 0]</td><td align=right>[lindex $row 1]</td><td align=right>[lindex $row 2]</td><td align=right>[lindex $row 3]</td><td align=right>[format %4.2f [expr 100*(double([lindex $row 1]+[lindex $row 2]-[lindex $row 3])/double([lindex $row 1]+[lindex $row 2]))]]%</td></tr>\n"
    }
}
ns_write "</table>

</blockquote>

<p>

The SQL:

<pre>
select 
  username, consistent_gets, block_gets, physical_reads 
from 
  V\$SESSION, V\$SESS_IO 
where
  V\$SESSION.SID = V\$SESS_IO.SID and (Consistent_gets + block_gets > 0) and Username is not null
</pre>

[annotated_archive_reference 38]

[ad_admin_footer]
"
