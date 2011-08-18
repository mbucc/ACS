# $Id: canned-responses.tcl,v 3.0 2000/02/06 03:17:38 ron Exp $
set db [ns_db gethandle]

ReturnHeaders

ns_write "[ad_admin_header "Canned Responses"]
<h2>Canned Responses</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] "Canned Responses"]

<hr>

<h3>Defined Responses</h3>
<ul>
"

set selection [ns_db select $db "select response_id, one_line, response_text
from ec_canned_responses
order by one_line"]

set count 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    ns_write "<li><a href=\"canned-response-edit.tcl?response_id=$response_id\">$one_line</a>
<blockquote>
[ec_display_as_html $response_text] <a href=\"canned-response-delete.tcl?response_id=$response_id\">Delete</a>
</blockquote>
"

    incr count
}

if { $count == 0 } {
    ns_write "<li>No defined canned responses.\n"
}

ns_write "<p>
<a href=\"canned-response-add.tcl\">Add a new canned response</a>
</ul>

[ad_admin_footer]
"