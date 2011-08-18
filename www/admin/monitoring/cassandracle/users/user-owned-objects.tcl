# $Id: user-owned-objects.tcl,v 3.0 2000/02/06 03:25:43 ron Exp $
ReturnHeaders
ns_write "

[ad_admin_header "User owned objects"]

<h2>User owned objects</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] [list "/admin/monitoring/cassandracle/users/index.tcl" "Users"] "Objects"]

<hr>
<table>
<tr><th>Owner</th><th>Object Type</th><th>Count</th></tr>
"

set db [cassandracle_gethandle]


set the_query "
select 
  owner, object_type, count(*)
from
  dba_objects
where
  owner<>'SYS'
group by
  owner, object_type"

set object_ownership_info [database_to_tcl_list_list $db $the_query]

if {[llength $object_ownership_info]==0} {
    ns_write "<tr><td>No objects found!</td></tr>"
} else {
    set current_user ""
    
    foreach row $object_ownership_info {
    if {$current_user==""} {
	set current_user [lindex $row 0]
	ns_write "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"one-user-specific-objects.tcl?owner=$current_user&object_type=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td></tr>\n"
	continue
   }
   if {[lindex $row 0]!=$current_user} {
       set current_user [lindex $row 0]
       ns_write "<tr><td valign=top align=left>[lindex $row 0]</td><td valign=top align=left><a href=\"one-user-specific-objects.tcl?owner=$current_user&object_type=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td></tr>\n"
    } else {
	ns_write "<tr><td>&nbsp;</td><td valign=top align=left><a href=\"one-user-specific-objects.tcl?owner=$current_user&object_type=[lindex $row 1]\">[lindex $row 1]</a></td><td valign=top align=right>[lindex $row 2]</td></tr>\n"
    }
}
}
ns_write "</table>\n
<p>
The SQL:
<pre>
$the_query
</pre>
[ad_admin_footer]
"
