# canned-response-edit.tcl

ad_page_contract {
    @param response_id
    @author
    @creation-date
    @cvs-id canned-response-edit.tcl,v 3.1.6.4 2000/09/22 01:34:51 kevin Exp
} {
    response_id
}



db_1row get_response_info "select one_line, response_text
from ec_canned_responses
where response_id = :response_id"




doc_return  200 text/html "[ad_admin_header "Edit Canned Response"]
<h2>Edit Canned Response</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "canned-responses.tcl" "Canned Responses"] "Edit Canned Response"]

<hr>

<form action=canned-response-edit-2 method=POST>
[export_form_vars response_id]
<table noborder>
<tr><th>Description</th><td><input type=text size=60 name=one_line value=\"[philg_quote_double_quotes $one_line]\"></tr>
<tr><th>Text</th><td><textarea name=response_text rows=5 cols=70 wrap=soft>$response_text</textarea></tr>
<tr><td align=center colspan=2><input type=submit value=Submit></tr>
</table>
</form>

[ad_admin_footer]
"






