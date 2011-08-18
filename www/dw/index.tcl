# $Id: index.tcl,v 3.0 2000/02/06 03:38:35 ron Exp $
ReturnHeaders

ns_write "
[ad_header "Query [dw_system_name]"]

<h2>Query</h2>

<a href=/>[dw_system_name]</a>

<hr>

<ul>
<li><a href=\"query-new.tcl\">define a new query</a>

<p>
"

set db [ns_db gethandle]
set selection [ns_db select $db "select * from queries order by definition_time desc"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"query.tcl?query_id=$query_id\">$query_name</a>\n"
}

ns_write "

</ul>

[ad_footer]
"
