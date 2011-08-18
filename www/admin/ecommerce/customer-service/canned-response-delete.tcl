# $Id: canned-response-delete.tcl,v 3.0 2000/02/06 03:17:34 ron Exp $
set_form_variables
# response_id


set db [ns_db gethandle]

set selection [ns_db 1row $db "select one_line, response_text
from ec_canned_responses
where response_id = $response_id"]

set_variables_after_query

ns_return 200 text/html "[ad_admin_header "Confirm Delete"]

<h2>Confirm Delete</h2>

<hr>

Are you sure you want to delete this canned response?

<h3>$one_line</h3>
[ec_display_as_html $response_text]

<p>

<center>
<a href=\"canned-response-delete-2.tcl?response_id=$response_id\">Yes, get rid of it</a>
</center>


[ad_admin_footer]
"