# $Id: custom-field.tcl,v 3.0 2000/02/06 03:19:58 ron Exp $
set_the_usual_form_variables

# field_identifier

set db [ns_db gethandle]
set selection [ns_db 1row $db "select field_name, default_value, column_type, active_p from ec_custom_product_fields where field_identifier='$QQfield_identifier'"]
set_variables_after_query

ReturnHeaders

ns_write "[ad_admin_header "$field_name"]

<h2>$field_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "custom-fields.tcl" "Custom Fields"] "One Custom Field"]

<hr>

<table noborder>
<tr>
<td>Unique Identifier:</td>
<td>$field_identifier</td>
</tr>
<tr>
<td>Field Name:</td>
<td>$field_name</td>
</tr>
<tr>
<td>Default Value:</td>
<td>$default_value</td>
</tr>
<tr>
<td>Kind of Information:</td>
<td>[ec_pretty_column_type $column_type]</td>
</tr>
<tr>
<td>Active:</td>
<td>[util_PrettyBoolean $active_p]</td>
</tr>
</table>

<p>

<h3>Actions:</h3>

<p>

<ul>
<li><a href=\"custom-field-edit.tcl?field_identifier=$field_identifier\">Edit</a>
"

if { $active_p == "t" } {
    ns_write "<li><a href=\"custom-field-status-change.tcl?field_identifier=$field_identifier&active_p=f\">Make Inactive</a>"
} else {
    ns_write "<li><a href=\"custom-field-status-change.tcl?field_identifier=$field_identifier&active_p=t\">Reactivate</a>"
}

# Set audit variables
# audit_name, id, id_column, return_url, audit_tables, main_tables
set audit_name "$field_name"
set id $field_identifier
set id_column "field_identifier"
set return_url "custom-field.tcl?[export_url_vars field_identifier]"
set audit_tables [list ec_custom_product_fields_audit]
set main_tables [list ec_custom_product_fields]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name id id_column return_url audit_tables main_tables]\">Audit Trail</a>
</ul>

[ad_admin_footer]
"