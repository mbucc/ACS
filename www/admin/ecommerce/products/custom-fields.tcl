# $Id: custom-fields.tcl,v 3.0 2000/02/06 03:19:59 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Custom Fields"]

<h2>Custom Fields</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Custom Fields"]

<hr>

<ul>

"

set db [ns_db gethandle]
set selection [ns_db select $db "select field_identifier, field_name, active_p from ec_custom_product_fields order by active_p desc, field_name"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"custom-field.tcl?field_identifier=$field_identifier\">$field_name</a>"
    if { $active_p == "f" } {
	ns_write " (inactive)"
    }
    ns_write "\n"
}

set table_names_and_id_column [list ec_custom_product_fields ec_custom_product_fields_audit field_identifier]

ns_write "<p>

<li><a href=\"custom-field-add.tcl\">Add a custom field</a>

<p>

<li><a href=\"/admin/ecommerce/audit-tables.tcl?[export_url_vars table_names_and_id_column]\">Audit All Custom Fields</a>
</ul>
[ad_admin_footer]
"