# $Id: index.tcl,v 3.0 2000/02/06 03:25:45 ron Exp $
ns_return 200 text/html "[ad_admin_header "[ad_system_name] Configuration"]

<h2>[ad_system_name] Configuration</h2>

[ad_admin_context_bar  [list "/admin/monitoring/index.tcl" "Monitoring"] "Configuration"]

<hr>
<ul>
<li>IP Address: [ns_conn peeraddr]
<li>System Name: [ad_parameter SystemName]
<li>System Owner: <a href=mailto://[ad_parameter SystemOwner]>[ad_parameter SystemOwner]</a>
</ul>

[ad_admin_footer]
"
