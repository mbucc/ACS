# $Id: concurrent-active-users.tcl,v 3.0 2000/02/06 03:25:32 ron Exp $
set page_name "Concurrent Active Users"
set db [cassandracle_gethandle]
db_query_to_vars $db "select * from V\$LICENSE"
if {$sessions_max=="0"} {set sessions_max "unspecified."}
if {$sessions_warning=="0"} {set sessions_warning "No warning level specified."}
if {$users_max=="0"} {set users_max "unspecified."}


ns_return 200 text/html "

[ad_admin_header "$page_name"]

<h2>$page_name</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] [list \"/admin/monitoring/cassandracle/users/\" "Users"] [list "/admin/monitoring/cassandracle/users/user-owned-objects.tcl" "Objects" ] "One Object"]


<hr>

<ul>

<h4>What you paid for</h4>

<li>LICENSE_MAX_SESSIONS: $sessions_max
<li>LICENSE_SESSIONS_WARNING: $sessions_warning
<li>LICENSE_MAX_USERS: $users_max


<h4>What you're actually doing</h4>

<li>Number current sessions: $sessions_current
<li>Sessions Highwater Mark: $sessions_highwater

</ul>

The SQL:

<pre>
select * from V\$LICENSE
</pre>

[ad_admin_footer]
"