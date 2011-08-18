# $Id: audit-tables.tcl,v 3.0 2000/02/06 03:16:48 ron Exp $
# Jesse 7/18
# Gives user a list of tables to audit

set_form_variables 0
# possibly table_names_and_id_column

set db [ns_db gethandle]

ReturnHeaders
ns_write "
[ad_admin_header "Audit [ec_system_name]"]

<h2>Audit [ec_system_name]</h2>

[ad_admin_context_bar [list "index.tcl" Ecommerce] "Audit Tables"]

<hr>

<center>
This page will let you see all changes to one table of the [ec_system_name] database over a specified period of time. <b>It is recommended that you start with a narrow time window and expand as needed. Some tables are very large.</b>
</center>

<form method=post action=\"audit-table.tcl\">

<ul>
"

if { [info exists table_names_and_id_column] } {
    ns_write "[export_form_vars table_names_and_id_column]
    <blockquote>
    Audit for table [lindex $table_names_and_id_column 0]
    </blockquote>
"
} else {
    ns_write "
<li>What table do you want to audit:
<select name=table_names_and_id_column>
<option value=\"ec_products ec_products_audit product_id\">Products
<option value=\"ec_templates ec_templates_audit template_id\">Templates
<option value=\"ec_user_classes ec_user_classes_audit user_class_id\">User Classes
<option value=\"ec_user_class_user_map ec_user_class_user_map_audit user_class_id\">User Class to User Map by User class
<option value=\"ec_user_class_user_map ec_user_class_user_map_audit user_id\">User Class to User Map by User
<option value=\"ec_categories ec_categories_audit category_id\">Categories
<option value=\"ec_subcategories ec_subcategories_audit subcategory_id\">Subcategories
<option value=\"ec_subsubcategories ec_subsubcategories_audit subsubcategory_id\">Subsubcategories
<option value=\"ec_email_templates ec_email_templates_audit email_template_id\">Email Templates
<option value=\"ec_product_links ec_product_links_audit product_a\">Links from a Product
<option value=\"ec_product_links ec_product_links_audit product_b\">Links to a Product
<option value=\"ec_sales_tax_by_state ec_sales_tax_by_state_audit usps_abbrev\">Sales Tax
<option value=\"ec_product_comments ec_product_comments_audit comment_id\">Customer Reviews
<option value=\"ec_admin_settings ec_admin_settings_audit 1\">Shipping Costs (and other defaults)
<option value=\"ec_custom_product_fields ec_custom_product_fields_audit field_identifier\">Custom Product Fields
<option value=\"ec_category_product_map ec_category_product_map_audit category_id\">Category to Product Map by category
<option value=\"ec_category_product_map ec_category_product_map_audit product_id\">Category to Product Map by product
<option value=\"ec_subcategory_product_map ec_subcategory_product_map_audit subcategory_id\">Subcategory to Product Map by subcategory
<option value=\"ec_subcategory_product_map ec_subcategory_product_map_audit product_id\">Subcategory to Product Map by product
<option value=\"ec_subsubcategory_product_map ec_subsubcat_product_map_audit subsubcategory_id\">Subusbcategory to Product Map by subsubcategory
<option value=\"ec_subsubcategory_product_map ec_subsubcat_product_map_audit product_id\">Subusbcategory to Product Map by product
</select>
"
}

ns_write "
<p>

<li>When do you want to audit back to: (Leave blank to start at the begining of the table's history.)<br>
[ad_dateentrywidget start_date ""] [ec_timeentrywidget start_date ""]

<p>

<li>When do you want to audit up to:<br>
[ad_dateentrywidget end_date] [ec_timeentrywidget end_date]

</ul>

<center>
<b>Note: if the table is very large, this may take a while.</b><br>
<input type=submit value=Audit>
</center>

</form>

[ad_admin_footer]
"
