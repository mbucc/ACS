# $Id: edit.tcl,v 3.0 2000/02/06 03:21:45 ron Exp $
set_the_usual_form_variables
# template_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select template_name, template from ec_templates where template_id=$template_id"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "Edit Template"]

<h2>Edit Template</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] [list "one.tcl?template_id=$template_id" "$template_name"] "Edit Template"]

<hr>

<form method=post action=edit-2.tcl>
[export_form_vars template_id]

Name: <input type=text name=template_name size=30 value=\"[philg_quote_double_quotes $template_name]\">

<p>

ADP template:<br>
<textarea name=template rows=30 cols=60>$template</textarea>

<p>

<center>
<input type=submit value=\"Submit Changes\">
</center>

</form>

[ad_admin_footer]
"
