# /www/admin/monitoring/cassandracle/index.tcl

ad_page_contract {

    Stepping stone to the individual Oracle status queries

    @author Jin Choi (jsc@arsdigita.com)
    @cvs-id index.tcl,v 3.2.6.5 2000/09/22 01:35:34 kevin Exp

} { }

doc_return  200 text/html "
[ad_admin_header "Cassandracle"]

<h2>Cassandracle</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] "Cassandracle"]

<hr>

<ul>

<h4>by question</h4>

<li><a href=\"./oracle-settings\">What are the initialization parameters?</a>
<li><a href=\"tablespaces/space-usage\">How full are my tablespaces?</a>
<li><a href=\"users/hit-ratio\">Are any users becoming pigs?</a>
<li><a href=\"performance/pct-large-table-scans\">Are any queries becoming pigs?</a>
<li>Are any tables becoming pigs?
<li><a href=\"users/sessions-info\">Who is connected to the DB, and what can you tell me about their sessions?</a>
<li><a href=\"performance/data-block-waits\">Are there any performance bottlenecks in the DB?</a>
<li><a href=\"objects/list-all-functions-and-procedures\">What PL/SQL procedures and functions are defined?</a>
<li><a href=\"users/user-owned-objects\">What objects are defined?</a>

<h4>by object</h4>

<li><a href=\"users/\">Users</a>
<li><a href=\"tablespaces/space-usage\">Tablespaces</a>
</ul>
[ad_admin_footer]
"
