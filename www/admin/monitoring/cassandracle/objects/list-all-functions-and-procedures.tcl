# $Id: list-all-functions-and-procedures.tcl,v 3.0 2000/02/06 03:25:26 ron Exp $
set page_name "PL/SQL Functions and Procedures by User"
ReturnHeaders
set db [cassandracle_gethandle]

ns_write "
[ad_admin_header $page_name]
<h2>$page_name</h2>

[ad_admin_context_bar [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "All Functions and Procedures"]


<hr>
<table>
<tr><th>Owner</th><th>Object Name</th><th>Object Type</th><th>Date Created</th><th>Status</th></tr>
"

set object_info [database_to_tcl_list_list $db "
select
  owner, object_name, object_type, created, status
from
  dba_objects
where
  (object_type='FUNCTION' or object_type='PROCEDURE')
group by
  owner, object_type, object_name, created, status
order by
  owner, object_name"]

if {[llength $object_info]==0} {
    ns_write "<tr><td>No objects found!</td></tr>"
} else {
    set current_user ""
    
    foreach row $object_info {
    if {$current_user==""} {
	set current_user [lindex $row 0]
	ns_write "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"detail-function-or-procedure.tcl?owner=$current_user&object_name=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td><td valign=top align=right>[lindex $row 4]</td></tr>\n"
	continue
   }
   if {[lindex $row 0]!=$current_user} {
       set current_user [lindex $row 0]
       ns_write "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"detail-function-or-procedure.tcl?owner=$current_user&object_name=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td><td valign=top align=right>[lindex $row 4]</td></tr>\n"
    } else {
	ns_write "<tr><td>&nbsp;</td><td valign=top align=left><a href=\"detail-function-or-procedure.tcl?owner=$current_user&object_name=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td><td valign=top align=right>[lindex $row 3]</td><td valign=top align=right>[lindex $row 4]</td></tr>\n"
    }
}
}
ns_write "
</table>

<p>

The SQL:

<pre>
select
  owner, object_name, object_type, created, status
from
  dba_objects
where
  (object_type='FUNCTION' or object_type='PROCEDURE')
group by
  owner, object_type, object_name, created, status
order by
  owner, object_name
</pre>

[ad_admin_footer]
"
