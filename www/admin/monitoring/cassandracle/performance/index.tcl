ad_page_contract {
    Displays options for monitoring database performance.

    @cvs-id index.tcl,v 3.2.2.3 2000/09/22 01:35:36 kevin Exp
} {
}

doc_return  200 text/html "
[ad_admin_header "Performance"]

<h2>Performance</h2>

[ad_admin_context_bar  [list "/admin/monitoring" "Monitoring"] [list "/admin/monitoring/cassandracle" "Cassandracle"] "Performance"]

<hr>

<ul>
<li><a href=\"pct-large-table-scans\">Large Table Scans</a>

<li><a href=\"data-block-waits\">Data Block Waits</a>

</ul>

[ad_admin_footer]
"
