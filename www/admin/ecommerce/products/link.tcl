# $Id: link.tcl,v 3.0 2000/02/06 03:20:17 ron Exp $
# link.tcl
#
# by eveander@arsdigita.com June 1999
#
# lets admin maintain links among products (e.g., "you should also think 
# about buying X if you're buying Y")

set_the_usual_form_variables

# product_id

set product_name [ec_product_name $product_id]

ReturnHeaders

ns_write "[ad_admin_header "Links between $product_name and other products"]

<h2>Links</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" "One"] "Links"]

<hr>

Links <b>from</b> the page for $product_name to other products' display pages:

<p>

<ul>
"
set db [ns_db gethandle]

set selection [ns_db select $db "select product_b, product_name as product_b_name
from ec_product_links, ec_products
where product_a=$product_id
and product_b=ec_products.product_id"]

set product_counter 0
while { [ns_db getrow $db $selection] } {
    incr product_counter
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?product_id=$product_b&product_name=[ns_urlencode $product_b_name]\">$product_b_name</a> \[<a href=\"link-delete.tcl?[export_url_vars product_id product_name]&product_a=$product_id&product_b=$product_b\">delete link</a>\]\n"
}

if { $product_counter == 0 } {
    ns_write "None\n"
}

ns_write "</ul>

<p>

Links <b>to</b> $product_name from other products' display pages:

<p>

<ul>
"

set selection [ns_db select $db "select product_a, product_name as product_a_name
from ec_product_links, ec_products
where product_b=$product_id
and ec_product_links.product_a=ec_products.product_id"]

set product_counter 0
while { [ns_db getrow $db $selection] } {
    incr product_counter
    set_variables_after_query
    ns_write "<li><a href=\"one.tcl?product_id=$product_a&product_name=[ns_urlencode $product_a_name]\">$product_a_name</a> \[<a href=\"link-delete.tcl?[export_url_vars product_id product_name]&product_a=$product_a&product_b=$product_id\">delete link</a>\]\n"
}

if { $product_counter == 0 } {
    ns_write "None\n"
}

ns_write "</ul>

<p>

Search for a product to add a link to/from:

<p>

<blockquote>

<form method=post action=link-add.tcl>
[export_form_vars product_id product_name]
Name: <input type=text name=link_product_name size=20>
<input type=submit value=\"Search\">
</form>

<p>

<form method=post action=link-add.tcl>
[export_form_vars product_id product_name]
ID: <input type=text name=link_product_id size=3>
<input type=submit value=\"Search\">
</form>

</blockquote>
"

# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name "Links from $product_name"
set audit_id $product_id
set audit_id_column "product_a"
set return_url "[ns_conn url]?[export_url_vars product_id]"
set audit_tables [list ec_product_links_audit]
set main_tables [list ec_product_links]

ns_write "
<h3>Audit Trail</h3>

<ul>
<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Links from $product_name</a>

<p>
"

set audit_name "Links to $product_name"
set audit_id_column "product_b"

ns_write "
<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Links to $product_name</a>

</ul>

[ad_admin_footer]
"
