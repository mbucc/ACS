# $Id: one.tcl,v 3.0 2000/02/06 03:21:50 ron Exp $
set_the_usual_form_variables
# template_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select template_name, template from ec_templates where template_id=$template_id"]
set_variables_after_query

set default_template_id [database_to_tcl_string $db "select default_template from ec_admin_settings"]

ReturnHeaders

ns_write "[ad_admin_header "$template_name"]

<h2>$template_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] "One Template"]

<hr>
"

if { $template_id == $default_template_id } {
    ns_write "<b>This is the default template used for product display.</b><p>"
}

ns_write "<h3>The template:</h3>

<blockquote>
<pre>
[ns_quotehtml $template]
</pre>
</blockquote>

<p>

<h3>Actions:</h3>

<ul>
<li><a href=\"edit.tcl?[export_url_vars template_id]\">Edit</a>
<li><a href=\"add.tcl?based_on=$template_id\">Create new template based on this one</a>
"
if { $template_id != $default_template_id } {
    ns_write "<li><a href=\"default.tcl?[export_url_vars template_id]\">Make this template be the default template</a>\n"
}

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$template_name"
set audit_id $template_id
set audit_id_column "template_id"
set return_url "[ns_conn url]?[export_url_vars template_id]"
set audit_tables [list ec_templates_audit]
set main_tables [list ec_templates]

ns_write "<li><a href=\"category-associate.tcl?[export_url_vars template_id]\">Associate this template with a product category</a>
<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>
<li><a href=\"delete.tcl?[export_url_vars template_id]\">Delete</a>
</ul>

[ad_admin_footer]
"
