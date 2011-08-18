# $Id: index.tcl,v 3.0 2000/02/06 03:25:28 ron Exp $
ns_return 200 text/html "
[ad_admin_header "Performance"]

<h2>Performance</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Performance"]


<hr>

<ul>
<li><a href=\"pct-large-table-scans.tcl\">Large Table Scans</a>

<li><a href=\"data-block-waits.tcl\">Data Block Waits</a>

</ul>


[ad_admin_footer]
"
