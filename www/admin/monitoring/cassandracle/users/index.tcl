# $Id: index.tcl,v 3.0 2000/02/06 03:25:34 ron Exp $
#what we want to know for a user:
#info about a session
#info about ownership
#space usage


ns_return 200 text/html "

[ad_admin_header "Users"]

<h2>Users</h2>

[ad_admin_context_bar [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Users"]

<hr>

<ul>
<li><a href=\"sessions-info.tcl\">Who is connected and what query did they last run?</a>

<li><a href=\"user-owned-objects.tcl\">Who owns which objects?</a>
<li><a href=\"user-owned-constraints.tcl\">Who owns which constraints?</a>

<p>

<li><a href=\"concurrent-active-users.tcl\">From an Oracle license point of view, 
how many users on the system now and how does this compare to the limits?</a>

</ul>
[ad_admin_footer]
"
