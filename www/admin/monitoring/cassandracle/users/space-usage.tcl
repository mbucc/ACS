# $Id: space-usage.tcl,v 3.0 2000/02/06 03:25:41 ron Exp $
set page_name "Tablespace Block Allocation by User"
ReturnHeaders
set db [cassandracle_gethandle]

ns_write "
[ad_admin_header $page_name]
This table sums up the blocks allocated in each segment of a tablespace by a user.<p>
<table>
<tr><th>User</th><th>Tablespace Name</th><th>Blocks Allocated</th><th>Total Space for this Tablespace</th></tr>
"


#"select username, tablespace_name, blocks, max_blocks from dba_ts_quotas order by username, tablespace_name"

set tablespace_usage_info [database_to_tcl_list_list $db "select S.owner, S.tablespace_name, sum(S.blocks), DF.Blocks from dba_segments S, DBA_DATA_FILES DF where S.tablespace_name=DF.tablespace_name group by S.owner, S.tablespace_name, DF.Blocks order by S.owner, S.tablespace_name, DF.blocks"]

if {[llength $tablespace_usage_info]==0} {
    ns_write "<tr><td>No data segments found!</td></tr>"
} else {
    set current_user ""
    
    foreach row $tablespace_usage_info {
    if {$current_user==""} {
	ns_write "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td></tr>\n"
	set current_user [lindex $row 0]
	continue
   }
   if {[lindex $row 0]!=$current_user} {
	#finish the remaining tablespace
	ns_write "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td></tr>\n"
       set current_user [lindex $row 0]
    } else {
	ns_write "<tr><td>&nbsp;</td><td valign=top align=left>[lindex $row 1]</td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td></tr>\n"
    }
}
}
ns_write "</table>\n
<p>
Here is the SQL responsible for this information: <p>
<kbd>select S.owner, S.tablespace_name, sum(S.blocks), DF.Blocks<br>
from dba_segments S, DBA_DATA_FILES DF<br>
where S.tablespace_name=DF.tablespace_name<br>
group by S.owner, S.tablespace_name, DF.Blocks<br>
order by S.owner, S.tablespace_name, DF.blocks</kbd>
[ad_admin_footer]
"
