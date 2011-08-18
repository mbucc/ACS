# $Id: canned-response-edit.tcl,v 3.0 2000/02/06 03:17:37 ron Exp $
set_form_variables
# response_id

set db [ns_db gethandle]

set selection [ns_db 1row $db "select one_line, response_text
from ec_canned_responses
where response_id = $response_id"]

set_variables_after_query

ns_return 200 text/html "[ad_admin_header "Edit Canned Response"]
<h2>Edit Canned Response</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "canned-responses.tcl" "Canned Responses"] "Edit Canned Response"]

<hr>

<form action=canned-response-edit-2.tcl method=POST>
[export_form_vars response_id]
<table noborder>
<tr><th>Description</th><td><input type=text size=60 name=one_line value=\"[philg_quote_double_quotes $one_line]\"></tr>
<tr><th>Text</th><td><textarea name=response_text rows=5 cols=70 wrap=soft>$response_text</textarea></tr>
<tr><td align=center colspan=2><input type=submit value=Submit></tr>
</table>
</form>

[ad_admin_footer]
"