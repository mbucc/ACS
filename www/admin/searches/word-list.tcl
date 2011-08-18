# $Id: word-list.tcl,v 3.0 2000/02/06 03:28:25 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "User Searches - words"]

<h2>User Searches - words</h2>

recorded by the <a href=\"index.tcl\">search tracking</a> of <a href=\"/admin/index.tcl\">[ad_system_name] administration</a>

<hr>

<h3>Searched words</h3>
<ul>"

set db [ns_db gethandle]

set selection [ns_db select $db "select distinct query_string
from query_strings
order by lower(query_string) asc"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a href=\"by-word.tcl?query_string=[ns_urlencode $query_string]\">$query_string</a>"
}

ns_write "</ul>
[ad_admin_footer]
"























