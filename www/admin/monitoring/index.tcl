
ad_page_contract {
    @cvs-id index.tcl,v 3.5.2.6 2000/09/22 01:35:33 kevin Exp
} {}

doc_return  200 text/html "[ad_admin_header "Monitoring  [ad_system_name]"]

<h2>Monitoring  [ad_system_name]</h2>

[ad_admin_context_bar "Monitoring"]

<hr>
<ul>

<li><a href=\"/monitor\">Current page requests</a>
<li><a href=\"cassandracle\">Cassandracle</a> (Oracle)
<li><a href=\"configuration\">Configuration</a>
<li><a href=\"watchdog\">WatchDog</a> (Error Log)
<li><a href=\"db-logging\">Database Logging</a>
(log messages written from within PL/SQL)
<li><a href=\"filters\">Filters</a>
<li><a href=\"registered-procs\">Registered Procedures</a>
<li><a href=\"scheduled-procs\">Scheduled Procedures</a>
<li><a href=\"startup-log\">Startup Log</a>
<li><a href=\"top\">Statistics from top</a>
<li><a href=\"analyze\">Table analysis</a>
<li><a href=\"/admin/developer-support\">Developer Support Request Information</a>
</ul>

[ad_admin_footer]
"



