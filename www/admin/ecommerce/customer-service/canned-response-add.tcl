# canned-response-add.tcl

ad_page_contract {
    @author
    @creation-date
    @cvs-id canned-response-add.tcl,v 3.1.6.4 2000/09/22 01:34:51 kevin Exp
} {
}


doc_return  200 text/html "[ad_admin_header "New Canned Response"]
<h2>New Canned Response</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "canned-responses.tcl" "Canned Responses"] "New Canned Response"]

<hr>

<form action=canned-response-add-2 method=POST>
<table noborder>
<tr><th>Description</th><td><input type=text size=60 name=one_line></tr>
<tr><th>Text</th><td><textarea name=response_text rows=5 cols=70 wrap=soft></textarea></tr>
<tr><td align=center colspan=2><input type=submit value=Submit></tr>
</table>
</form>

[ad_admin_footer]
"
