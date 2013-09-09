# /www/admin/ecommerce/products/custom-fields.tcl
ad_page_contract {
  Admin page for custom product fields.

  @author Eve Andersson (eveander@arsdigita.com)
  @creation-date Summer 1999
  @cvs-id custom-fields.tcl,v 3.1.6.3 2000/08/20 22:35:01 seb Exp
} {
}

doc_body_append "[ad_admin_header "Custom Fields"]

<h2>Custom Fields</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index" "Products"] "Custom Fields"]

<hr>

<ul>

"

db_foreach custom_fields_select "
select field_identifier, field_name, active_p
from ec_custom_product_fields
order by active_p desc, field_name
" {
  doc_body_append "<li><a href=\"custom-field?field_identifier=$field_identifier\">$field_name</a>"
  if { $active_p == "f" } {
    doc_body_append " (inactive)"
  }
  doc_body_append "\n"
}

set table_names_and_id_column [list ec_custom_product_fields ec_custom_product_fields_audit field_identifier]

doc_body_append "<p>

<li><a href=\"custom-field-add\">Add a custom field</a>

<p>

<li><a href=\"/admin/ecommerce/audit-tables?[export_url_vars table_names_and_id_column]\">Audit All Custom Fields</a>
</ul>
[ad_admin_footer]
"
