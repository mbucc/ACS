# $Id: make-default.tcl,v 3.0 2000/02/06 03:21:49 ron Exp $
set_the_usual_form_variables
# template_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select template_name, template from ec_templates where template_id=$template_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Set Default Template"]

<h2>Set Default Template</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] [list "one.tcl?template_id=$template_id" "$template_name"] "Set as Default"]

<hr>

Please confirm that you want this to become the default template that products will be displayed with
if no template has been specifically assigned to them.

<p>
<form method=post action=make-default-2.tcl>
[export_form_vars template_id]
<center>
<input type=submit value=\"Confirm\">
</center>
</form>


[ad_admin_footer]
"
