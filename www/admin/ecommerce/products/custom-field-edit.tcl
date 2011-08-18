# $Id: custom-field-edit.tcl,v 3.0 2000/02/06 03:19:55 ron Exp $
set_the_usual_form_variables

# field_identifier

set db [ns_db gethandle]
set selection [ns_db 1row $db "select field_name, default_value, column_type, active_p from ec_custom_product_fields where field_identifier='$QQfield_identifier'"]
set_variables_after_query

set old_column_type $column_type

ReturnHeaders

ns_write "[ad_admin_header "Edit $field_name"]

<h2>Edit $field_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "custom-fields.tcl" "Custom Fields"] "Edit Custom Field"]

<hr>

<form method=post action=custom-field-edit-2.tcl>
[export_form_vars old_column_type field_identifier]

<table noborder>
<tr>
<td>Unique Identifier:</td>
<td><code>$field_identifier</code></td>
<td>This can't be changed.</td>
</tr>
<tr>
<td>Field Name:</td>
<td><input type=text name=field_name value=\"[philg_quote_double_quotes $field_name]\" size=25 maxlength=100></td>
<td></td>
</tr>
<tr>
<td>Default Value:</td>
<td><input type=text name=default_value value=\"[philg_quote_double_quotes $default_value]\" size=15 maxlength=100></td>
<td></td>
</tr>
<tr>
<td>Kind of Information:</td>
<td>[ec_column_type_widget $column_type]</td>
<td>We might not be able to change this, depending on what it is, what you're trying to change it to, and what values are already in the database for this field (you can always try it &amp; find out).</td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Submit Changes\">
</center>

[ad_admin_footer]
"