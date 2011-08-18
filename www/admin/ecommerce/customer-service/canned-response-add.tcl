# $Id: canned-response-add.tcl,v 3.0 2000/02/06 03:17:32 ron Exp $
ns_return 200 text/html "[ad_admin_header "New Canned Response"]
<h2>New Canned Response</h2>

[ad_admin_context_bar [list "../index.tcl" "Ecommerce"] [list "index.tcl" "Customer Service Administration"] [list "canned-responses.tcl" "Canned Responses"] "New Canned Response"]

<hr>

<form action=canned-response-add-2.tcl method=POST>
<table noborder>
<tr><th>Description</th><td><input type=text size=60 name=one_line></tr>
<tr><th>Text</th><td><textarea name=response_text rows=5 cols=70 wrap=soft></textarea></tr>
<tr><td align=center colspan=2><input type=submit value=Submit></tr>
</table>
</form>

[ad_admin_footer]
"