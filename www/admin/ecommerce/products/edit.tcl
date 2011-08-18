# $Id: edit.tcl,v 3.1 2000/03/07 04:12:53 eveander Exp $
# edit.tcl
#
# by eveander@arsdigita.com June 1999
# 
# form for the user to edit the main fields in the ec_product table 
# plus custom fields

set_the_usual_form_variables

# product_id

set product_name [ec_product_name $product_id]

ReturnHeaders

ns_write "[ad_admin_header "Edit $product_name"]

<h2>Edit $product_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" "One"] "Edit"]

<hr>

All fields are optional except Product Name.
<p>
"
set multiple_retailers_p [ad_parameter MultipleRetailersPerProductP ecommerce]

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]

set selection [ns_db 1row $db "select * from ec_products where product_id=$product_id"]
set_variables_after_query

ns_write "<form enctype=multipart/form-data method=post action=edit-2.tcl>
[export_form_vars product_id dirname]
<table>
<tr>
<td>Product Name</td>
<td colspan=2><input type=text name=product_name size=30 value=\"[philg_quote_double_quotes $product_name]\"></td>
</tr>
<tr>
<td>SKU</td>
<td><input type=text name=sku size=10 value=\"[philg_quote_double_quotes $sku]\"></td>
<td>It's not necessary to include a SKU because the system generates its own
internal product_id to uniquely distinguish products.</td>
</tr>
"

# have to deal with category widget

set category_list [database_to_tcl_list $db "select category_id from ec_category_product_map where product_id=$product_id"]

set subcategory_list [database_to_tcl_list $db "select subcategory_id from ec_subcategory_product_map where product_id=$product_id"]

set subsubcategory_list [database_to_tcl_list $db "select subsubcategory_id from ec_subsubcategory_product_map where product_id=$product_id"]


set categorization_default [ec_determine_categorization_widget_defaults $db $category_list $subcategory_list $subsubcategory_list]


ns_write "<tr>
<td>Product Category</td>
<td>[ec_category_widget $db t $categorization_default]</td>
<td>Choose as many categories as you like.  The product will
be displayed on the web site in each of the categories you select.</td>
</tr>
"
if { !$multiple_retailers_p } {
    ns_write "<tr>
    <td>Stock Status</td>
    <td colspan=2>[ec_stock_status_widget $stock_status]</td>
    </tr>
    "
} else {
    ns_write "[philg_hidden_input stock_status $stock_status]\n"
}
ns_write "<tr>
<td>One-Line Description</td>
<td colspan=2><input type=text name=one_line_description size=60 value=\"[philg_quote_double_quotes $one_line_description]\"></td>
</tr>
<tr>
<td>Additional Descriptive Text</td>
<td colspan=2><textarea wrap rows=6 cols=60 name=detailed_description>$detailed_description</textarea></td>
</tr>
<tr>
<td>Search Keywords</td>
<td colspan=2><textarea wrap rows=2 cols=60 name=search_keywords>$search_keywords</textarea></td>
</tr>
<tr>
<td>Picture</td>
<td><input type=file size=10 name=upload_file>"

set thumbnail [ec_linked_thumbnail_if_it_exists $dirname f]
if { ![empty_string_p $thumbnail] } {
    ns_write "<br>Your current picture is:<br>$thumbnail"
}

ns_write "</td>
<td>This picture (.gif or .jpg format) can be as large as you like.  A thumbnail will be automatically generated.  Note that file uploading doesn't work with Internet Explorer 3.0.</td>
</tr>
<tr>
<td>Color Choices</td>
<td><input type=text name=color_list size=40 value=\"[philg_quote_double_quotes $color_list]\"></td>
<td>This should be a comma-separated list of colors the user is allowed to choose from
when ordering.  If there are no choices, leave this blank.</td>
</tr>
<tr>
<td>Size Choices</td>
<td><input type=text name=size_list size=40 value=\"[philg_quote_double_quotes $size_list]\"></td>
<td>This should be a comma-separated list of sizes the user is allowed to choose from
when ordering.  If there are no choices, leave this blank.</td>
</tr>
<tr>
<td>Style Choices</td>
<td><input type=text name=style_list size=40 value=\"[philg_quote_double_quotes $style_list]\"></td>
<td>This should be a comma-separated list of styles the user is allowed to choose from
when ordering.  If there are no choices, leave this blank.</td>
</tr>
<tr>
<td>URL where the consumer can get more info on the product</td>
"
if { [empty_string_p $url] } {
    set url "http://"
}
ns_write "<td colspan=2><input type=text name=url size=50 value=\"[philg_quote_double_quotes $url]\"></td>
</tr>
"
if { !$multiple_retailers_p } {
    ns_write "<tr>
    <td>Regular Price</td>
    <td><input type=text size=6 name=price value=\"$price\"></td>
    <td>All prices are in [ad_parameter Currency ecommerce].  The price should
    be written as a decimal number (no special characters like \$).
    </tr>
    "
} else {
    ns_write "[philg_hidden_input price $price]\n"
}
ns_write "<tr>
<td>Should this product be displayed when the user does a search?</td>
<td><input type=radio name=present_p value=\"t\""

if { $present_p == "t" } {
    ns_write " checked "
}

ns_write ">Yes
&nbsp;&nbsp;
<input type=radio name=present_p value=\"f\""

if { $present_p == "f" } {
    ns_write " checked "
}

ns_write ">No
</td>
<td>You might choose \"No\" if this product is part of a series.</td>
</tr>
<tr>
<td>When does this product become available for purchase?</td>
<td>[ad_dateentrywidget available_date $available_date]</td>
</tr>
"
if { !$multiple_retailers_p } {
    ns_write "<tr>
    <td>Shipping Price</td>
    <td><input type=text size=6 name=shipping value=\"$shipping\"></td>
    <td rowspan=3 valign=top>The \"Shipping Price\", \"Shipping Price - Additional\", and \"Weight\" fields
    may or may not be applicable, depending on the 
    <a href=\"../shipping-costs/\">shipping rules</a> you have set up for
    your ecommerce system.</td>
    </tr>
    <tr>
    <td>Shipping Price - Additional per item if ordering more than 1 (leave blank if same as Shipping Price above)</td>
    <td><input type=text size=6 name=shipping_additional value=\"$shipping_additional\"></td>
    </tr>
    "
} else {
    ns_write "[philg_hidden_input shipping $shipping]\n[philg_hidden_input shipping_additional $shipping_additional]\n"
}
ns_write "<tr>
<td>Weight ([ad_parameter WeightUnits ecommerce])</td>
<td><input type=text size=3 name=weight value=\"$weight\"></td>
</tr>
<tr>
<td>Template</td>
<td>[ec_template_widget $db $category_list $template_id]</td>
<td>Select a template to use when displaying this product. If none is
selected, the product will be displayed with the system default template.</td>
</tr>
</table>

<p>
"

set n_user_classes [database_to_tcl_string $db "select count(*) from ec_user_classes"]
if { $n_user_classes > 0 && !$multiple_retailers_p} {
    ns_write "<h3>Special Prices for User Classes</h3>
    
    <p>

    <table noborder>
    "
    
    set selection [ns_db select $db "select user_class_id, user_class_name from ec_user_classes order by user_class_name"]

    set first_class_p 1

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<tr><td>$user_class_name</td>
	<td><input type=text name=price$user_class_id size=6 value=\"[database_to_tcl_string_or_null $db_sub "select price from ec_product_user_class_prices where product_id=$product_id and user_clasS_id=$user_class_id"]\"></td>
	"

	if { $first_class_p } {
	    set first_class_p 0
	    ns_write "<td valign=top rowspan=$n_user_classes>Enter prices (no
	    special characters like \$) only if you want people in
	    user classes to be charged a different price than the
	    regular price.  If you leave user class prices blank,
	    then the users will be charged regular price.</td>\n"
	}
	ns_write "</tr>\n"
    }
    ns_write "</table>\n"
}


if { [database_to_tcl_string $db "select count(*) from ec_custom_product_fields where active_p='t'"] > 0 } {

    ns_write "<h3>Custom Fields</h3>
    
    <p>

    <table noborder>
    "
    
    set selection [ns_db select $db "select field_identifier, field_name, default_value, column_type from ec_custom_product_fields where active_p='t' order by creation_date"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	ns_write "<tr><td>$field_name</td><td>[ec_custom_product_field_form_element $field_identifier $column_type [database_to_tcl_string $db_sub "select $field_identifier from ec_custom_product_field_values where product_id=$product_id"]]</td></tr>\n"
    }

    ns_write "</table>\n"
}

ns_write "<center>
<input type=submit value=\"Continue\">
</center>
</form>
[ad_admin_footer]
"
