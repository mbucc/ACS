# $Id: index.tcl,v 3.0 2000/02/06 03:25:13 ron Exp $
ns_return 200 text/html "
[ad_admin_header "Cassandracle"]

<h2>Cassandracle</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] "Cassandracle"]

<hr>

<ul>

<h4>by question</h4>

<li><a href=\"tablespaces/space-usage.tcl\">How are full are my tablespaces?</a>
<li><a href=\"users/hit-ratio.tcl\">Are any users becoming pigs?</a>
<li><a href=\"performance/pct-large-table-scans.tcl\">Are any queries becoming pigs?</a>
<li>Are any tables becoming pigs?
<li><a href=\"users/sessions-info.tcl\">Who is connected to the DB, and what can you tell me about their sessions?</a>
<li><a href=\"performance/data-block-waits.tcl\">Are there any performance bottlenecks in the DB?</a>
<li><a href=\"objects/list-all-functions-and-procedures.tcl\">What PL/SQL procedures and functions are defined?</a>
<li><a href=\"users/user-owned-objects.tcl\">What objects are defined?</a>

<h4>by object</h4>

<li><a href=\"users/\">Users</a>
<li><a href=\"tablespaces/space-usage.tcl\">Tablespaces</a>
</ul>
[ad_admin_footer]
"
