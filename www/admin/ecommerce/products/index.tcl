# $Id: index.tcl,v 3.0 2000/02/06 03:20:09 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Product Administration"]

<h2>Product Administration</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Products"]

<hr>

"

# For Audit tables
set table_names_and_id_column [list ec_products ec_products_audit product_id]

set db [ns_db gethandle]

set selection [ns_db 1row $db "select count(*) as n_products, round(avg(price),2) as avg_price from ec_products_displayable"]
set_variables_after_query

ns_write "

<ul>

<li>$n_products products 
(<a href=\"list.tcl\">All</a> | 
<a href=\"by-category.tcl\">By Category</a> |
<a href=\"add.tcl\">Add</a>)

<p>

<li><a href=\"recommendations.tcl\">Recommendations</a>
<li><a href=\"../cat/\">Categorization</a>
<li><a href=\"custom-fields.tcl\">Custom Fields</a>
<li><a href=\"upload-utilities.tcl\">Bulk upload products</a>

<p>

<form method=post action=search.tcl>
<li>Search by Name: <input type=text name=product_name size=20>
<input type=submit value=\"Search\">
</form>

<p>

<form method=post action=search.tcl>
<li>Search by ID: <input type=text name=product_id size=3>
<input type=submit value=\"Search\">
</form>

<p>

<li><a href=\"/admin/ecommerce/audit-tables.tcl?[export_url_vars table_names_and_id_column]\">Audit all Products</a>
</ul>

[ad_admin_footer]
"
