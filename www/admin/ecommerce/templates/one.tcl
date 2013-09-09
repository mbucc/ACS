#  www/admin/ecommerce/templates/one.tcl
ad_page_contract {
    @param template_id 
  @author
  @creation-date
  @cvs-id one.tcl,v 3.1.6.7 2000/09/22 01:35:05 kevin Exp
} {
    template_id:integer
}



db_1row get_template_data  "select template_name, template from ec_templates where template_id=:template_id"


set default_template_id [db_string get_default_template "select default_template from ec_admin_settings"]


set page_html "[ad_admin_header "$template_name"]

<h2>$template_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Product Templates"] "One Template"]

<hr>
"

if { $template_id == $default_template_id } {
    append page_html "<b>This is the default template used for product display.</b><p>"
}

append page_html "<h3>The template:</h3>

<blockquote>
<pre>
[ns_quotehtml $template]
</pre>
</blockquote>

<p>

<h3>Actions:</h3>

<ul>
<li><a href=\"edit?[export_url_vars template_id]\">Edit</a>
<li><a href=\"add?based_on=$template_id\">Create new template based on this one</a>
"
if { $template_id != $default_template_id } {
    append page_html "<li><a href=\"make-default?[export_url_vars template_id]\">Make this template be the default template</a>\n"
}

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "$template_name"
set audit_id $template_id
set audit_id_column "template_id"
set return_url "[ad_conn url]?[export_url_vars template_id]"
set audit_tables [list ec_templates_audit]
set main_tables [list ec_templates]

append page_html "<li><a href=\"category-associate?[export_url_vars template_id]\">Associate this template with a product category</a>
<li><a href=\"/admin/ecommerce/audit?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>
<li><a href=\"delete?[export_url_vars template_id]\">Delete</a>
</ul>

[ad_admin_footer]
"


doc_return  200 text/html $page_html


