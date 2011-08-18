# $Id: index.tcl,v 3.1 2000/02/26 12:54:49 jsalz Exp $
ns_return 200 text/html "[ad_admin_header "Monitoring  [ad_system_name]"]

<h2>Monitoring  [ad_system_name]</h2>

[ad_admin_context_bar "Monitoring"]

<hr>
<ul>
<li><a href=\"/monitor.tcl\">Current page requests</a>
<li><a href=\"cassandracle\">Cassandracle</a> (Oracle)
<li><a href=\"configuration\">Configuration</a>
<li><a href=\"watchdog\">WatchDog</a> (Error Log)
<li><a href=\"db-logging.tcl\">Database Logging</a>
(log messages written from within PL/SQL)
<li><a href=\"filters.tcl\">Filters</a>
<li><a href=\"scheduled-procs.tcl\">Scheduled Procedures</a>
</ul>

[ad_admin_footer]
"
