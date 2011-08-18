# $Id: add-3.tcl,v 3.1 2000/03/07 04:11:14 eveander Exp $
set_the_usual_form_variables
# product_name, sku, one_line_description, color_list, size_list, style_list,
# detailed_description, search_keywords, url, price, 
# present_p, available_date, shipping, shipping_additional, weight,
# product_id, linked_thumbnail, dirname, stock_status, template_id
# and all active custom fields (except ones that are boolean and weren't filled in)
# and price$user_class_id for all the user classes
# category_id_list, subcategory_id_list, subsubcategory_id_list

set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0


ReturnHeaders
ns_write "[ad_admin_header "Confirm New Product"]

<h2>Confirm New Product</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] "Add Product"]

<hr>
<h3>Please confirm that the information below is correct:</h3>
"

set currency [ad_parameter Currency ecommerce]
set multiple_retailers_p [ad_parameter MultipleRetailersPerProductP ecommerce]

set db [ns_db gethandle]

ns_write "<form method=post action=add-4.tcl>
<center>
<input type=submit value=\"Confirm\">
</center>
<blockquote>
$linked_thumbnail
<table noborder>
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
$sku
</td>
</tr>
<tr>
<td>
Categorization:
</td>
<td>
[ec_category_subcategory_and_subsubcategory_display $db $category_id_list $subcategory_id_list $subsubcategory_id_list]
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
"
if { !$multiple_retailers_p } {
    ns_write "<tr>
    <td>
    Regular Price:
    </td>
    <td>
    [ec_message_if_null [ec_pretty_price $price $currency]]
    </td>
    </tr>
    "
}
ns_write "<tr>
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
    Shipping Price
    </td>
    <td>
    [ec_message_if_null [ec_pretty_price $shipping $currency]]
    </td>
    </tr>
    <tr>
    <td>
    Shipping - Additional
    </td>
    <td>
    [ec_message_if_null [ec_pretty_price $shipping_additional $currency]]
    </td>
    </tr>
    "
}
ns_write "<tr>
<td>
Weight
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
	if { [info exists price$user_class_id] } {
	    ns_write "
	    <tr>
	    <td>
	    $user_class_name Price:
	</td>
	    <td>
	    [ec_message_if_null [ec_pretty_price [set price$user_class_id] $currency]]
	    </td>
	    </tr>
	    "
	}
    }
}

set selection [ns_db select $db "select field_identifier, field_name, column_type from ec_custom_product_fields where active_p = 't'"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { [info exists $field_identifier] } {
	ns_write "
	<tr>
	<td>
	$field_name
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
Template
</td>
<td>
[ec_message_if_null [database_to_tcl_string_or_null $db "select template_name from ec_templates where template_id='$template_id'"]]
</td>
</tr>
</table>
</blockquote>
<p>
[export_form_vars product_name sku category_id_list subcategory_id_list subsubcategory_id_list one_line_description detailed_description color_list size_list style_list search_keywords url price present_p available_date shipping shipping_additional weight template_id product_id dirname stock_status]
"

# also need to export custom field values
set additional_variables_to_export [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where active_p='t'"]

eval "ns_write \"\[export_form_vars $additional_variables_to_export\]\n\""

# and export each price$user_class_id
foreach user_class_id [database_to_tcl_list $db "select user_class_id from ec_user_classes"] {
    ns_write "[export_form_vars "price$user_class_id"]\n"
}

ns_write "<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"