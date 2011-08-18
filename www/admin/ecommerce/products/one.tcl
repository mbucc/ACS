# $Id: one.tcl,v 3.1 2000/03/07 04:14:24 eveander Exp $
# one.tcl 
#
# by eveander@arsdigita.com June 1999
# 
# main admin page for a single product
# 

set_the_usual_form_variables

# product_id

# Have to get everything about this product from ec_products, 
# ec_custom_product_field_values (along with the info about the fields from
# ec_custom_product_fields), ec_category_product_map, ec_subcategory_product_map, ec_subsubcategory_product_map

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set selection [ns_db 1row $db "select * from ec_products where product_id=$product_id"]
set_variables_after_query

# we know these won't conflict with the ec_products columns because of the constraint
# in custom-field-add-2.tcl
set selection [ns_db 1row $db "select * from ec_custom_product_field_values where product_id=$product_id"]
set_variables_after_query

set category_list [database_to_tcl_list $db "select category_id from ec_category_product_map where product_id=$product_id"]

set subcategory_list [database_to_tcl_list $db "select subcategory_id from ec_subcategory_product_map where product_id=$product_id"]

set subsubcategory_list [database_to_tcl_list $db "select subsubcategory_id from ec_subsubcategory_product_map where product_id=$product_id"]

set multiple_retailers_p [ad_parameter MultipleRetailersPerProductP ecommerce]
set currency [ad_parameter Currency ecommerce]

set n_professional_reviews [database_to_tcl_string $db "select count(*) from ec_product_reviews where product_id = $product_id"]

if { $n_professional_reviews == 0 } { 
    set product_review_anchor "none yet; click to add"
} else {
    set product_review_anchor $n_professional_reviews
}

set n_customer_reviews [database_to_tcl_string $db "select count(*) from ec_product_comments where product_id = $product_id"]

if { $n_customer_reviews == 0 } {
    set customer_reviews_link "none yet"
} else {
    set customer_reviews_link "<a href=\"../customer-reviews/index-2.tcl?[export_url_vars product_id]\">$n_customer_reviews</a>"
}

set n_links_to [database_to_tcl_string $db "select count(*) from ec_product_links where product_b = $product_id"]

set n_links_from [database_to_tcl_string $db "select count(*) from ec_product_links where product_a = $product_id"]

if { $multiple_retailers_p } {
    set price_row ""
} else {
    if { [database_to_tcl_string $db "select count(*) from ec_sale_prices_current where product_id=$product_id"] > 0 } {
	set sale_prices_anchor "on sale; view price"
    } else {
	set sale_prices_anchor "put on sale"	
    }
    set price_row "<tr>
    <td>
    Regular Price:
    </td>
    <td>
    [ec_message_if_null [ec_pretty_price $price $currency]]
    (<a href=\"sale-prices.tcl?[export_url_vars product_id]\">$sale_prices_anchor</a>)
    </td>
    </tr>
    "
}

if { $active_p == "t" } {
    set active_p_for_display "Active"
} else {
    set active_p_for_display "Discontinued"
}

set active_p_row "
<tr>
<td>
Active/Discontinued:
</td>
<td>
$active_p_for_display
(<a href=\"toggle-active-p.tcl?[export_url_vars product_id]\">toggle</a>)
</td>
</tr>
"

if [empty_string_p $dirname] {
    set dirname_cell "something is wrong with this product; there is no place to put files!"
} else {
    set dirname_cell "$dirname (<a href=\"supporting-files-upload.tcl?[export_url_vars product_id]\">Supporting Files</a>)"
}

ReturnHeaders

ns_write "[ad_admin_header "$product_name"]

<h2>$product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "One Product"]

<hr>

<ul>
<li>Professional Reviews:  <a href=\"reviews.tcl?[export_url_vars product_id]\">$product_review_anchor</a>

<li>Customer Reviews: $customer_reviews_link

<li>Cross-selling Links:  <a href=\"link.tcl?[export_url_vars product_id]\">$n_links_to to; $n_links_from from</a>

</ul>


<h3>Complete Record</h3>

<blockquote>

"

if { $active_p == "f" } {
    ns_write "<b>This product is discontinued.</b><p>\n"
}

ns_write "[ec_linked_thumbnail_if_it_exists $dirname]
<table noborder>
<tr>
<td>
Product ID:
</td>
<td>
$product_id
</td>
</tr>
<tr>
<td>
Product Name:
</td>
<td>
$product_name
</td>
</tr>
<tr>
<td>
SKU:
</td>
<td>
[ec_message_if_null $sku]
</td>
</tr>
$price_row
$active_p_row
<tr>
<td>
Categorization:
</td>
<td>
[ec_category_subcategory_and_subsubcategory_display $db $category_list $subcategory_list $subsubcategory_list]
</td>
</tr>
"
if { !$multiple_retailers_p } {
    ns_write "<tr>
    <td>
    Stock Status:
    </td>
    <td>
    "
    if { ![empty_string_p $stock_status] } {
	ns_write [ad_parameter "StockMessage[string toupper $stock_status]" ecommerce]
    } else {
	ns_write [ec_message_if_null $stock_status]
    }
    
    ns_write "</td>
    </tr>
    "
}
ns_write "<tr>
<td>
One-Line Description:
</td>
<td>
[ec_message_if_null $one_line_description]
</td>
</tr>
<tr>
<td>
Additional Descriptive Text:
</td>
<td>
[ec_display_as_html [ec_message_if_null $detailed_description]]
</td>
</tr>
<tr>
<td>
Search Keywords:
</td>
<td>
[ec_message_if_null $search_keywords]
</td>
</tr>
<tr>
<td>
Color Choices:
</td>
<td>
[ec_message_if_null $color_list]
</td>
</tr>
<tr>
<td>
Size Choices:
</td>
<td>
[ec_message_if_null $size_list]
</td>
</tr>
<tr>
<td>
Style Choices:
</td>
<td>
[ec_message_if_null $style_list]
</td>
</tr>
<tr>
<td>
URL:
</td>
<td>
[ec_message_if_null $url]
</td>
</tr>
<tr>
<td>
Display this product when user does a search?
</td>
<td>
[ec_message_if_null [ec_PrettyBoolean $present_p]]
</td>
</tr>
"
if { !$multiple_retailers_p } {
    ns_write "<tr>
    <td>
    Shipping Price:
    </td>
    <td>
    [ec_message_if_null [ec_pretty_price $shipping $currency]]
    </td>
    </tr>
    <tr>
    <td>
    Shipping - Additional:
    </td>
    <td>
    [ec_message_if_null [ec_pretty_price $shipping_additional $currency]]
    </td>
    </tr>
    "
}
ns_write "<tr>
<td>
Weight:
</td>
<td>
[ec_message_if_null $weight] [ec_decode $weight "" "" [ad_parameter WeightUnits ecommerce]]
</td>
</tr>
"
if { !$multiple_retailers_p } {

    set selection [ns_db select $db "select user_class_id, user_class_name from ec_user_classes order by user_class_name"]
    
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	set temp_price [database_to_tcl_string_or_null $db_sub "select price from ec_product_user_class_prices where product_id=$product_id and user_class_id=$user_class_id"]
	
	ns_write "
	<tr>
	<td>
	$user_class_name Price:
	</td>
	<td>
	[ec_message_if_null [ec_pretty_price $temp_price $currency]]
	</td>
	</tr>
	"
    }
}

set selection [ns_db select $db "select field_identifier, field_name, column_type from ec_custom_product_fields where active_p = 't'"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [info exists $field_identifier] } {
	ns_write "
	<tr>
	<td>
	$field_name:
	</td>
	<td>
	"
	if { $column_type == "char(1)" } {
	    ns_write "[ec_message_if_null [ec_PrettyBoolean [set $field_identifier]]]\n"
	} elseif { $column_type == "date" } {
	    ns_write "[ec_message_if_null [util_AnsiDatetoPrettyDate [set $field_identifier]]]\n"
	} else {
	    ns_write "[ec_display_as_html [ec_message_if_null [set $field_identifier]]]\n"
	}
	ns_write "</td>
	</tr>
	"
    }
}

ns_write "<tr>
<td>
Template:
</td>
<td>
[ec_message_if_null [database_to_tcl_string_or_null $db "select template_name from ec_templates where template_id='$template_id'"]]
</td>
</tr>
<tr>
<td>
Date Added:
</td>
<td>
[util_AnsiDatetoPrettyDate $creation_date]
</td>
</tr>
<tr>
<td>
Date Available:
</td>
<td>
[util_AnsiDatetoPrettyDate $available_date]
</td>
</tr>
<tr>
<td>
Directory Name (where image &amp; other product info is kept):
</td>
<td>
$dirname_cell
</td>
</tr>
</table>
(<a href=\"edit.tcl?[export_url_vars product_id]\">Edit</a>)
</blockquote>

<p>

<h3>Miscellaneous</h3>

<ul>
"
if { $multiple_retailers_p } {
    ns_write "<li><a href=\"offers.tcl?[export_url_vars product_id product_name]\">Retailer Offers</a>
    "
}

ns_write "
<p>
<li><a href=\"delete.tcl?[export_url_vars product_id product_name]\">Delete</a>
<p>
"
# Set audit variables
# audit_name, audit_id, audit_id_column, return_url, audit_tables, main_tables
set audit_name $product_name
set audit_id $product_id
set audit_id_column "product_id"
set return_url "[ns_conn url]?[export_url_vars product_id]"
set audit_tables [list ec_products_audit ec_custom_p_field_values_audit ec_category_product_map_audit ec_subcat_prod_map_audit ec_subsubcat_prod_map_audit]
set main_tables [list ec_products ec_custom_product_field_values ec_category_product_map ec_subcategory_product_map ec_subsubcategory_product_map]

ns_write "<li><a href=\"/admin/ecommerce/audit.tcl?[export_url_vars audit_name audit_id audit_id_column return_url audit_tables main_tables]\">Audit Trail</a>

</ul>
[ad_admin_footer]
"
