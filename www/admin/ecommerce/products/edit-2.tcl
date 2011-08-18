# $Id: edit-2.tcl,v 3.1 2000/03/07 04:11:50 eveander Exp $
set_the_usual_form_variables
# product_name, sku, one_line_description, detailed_description, color_choices,
# size_choices, style_choices, search_keywords, url, price
# present_p, available_date, shipping, shipping_additional, weight, stock_status
# and dirname, product_id, template_id
# and all active custom fields (except ones that are boolean and weren't filled in)
# and price$user_class_id for all the user classes
# - categorization is a select multiple, so that will be dealt with separately
# - the dates are special (as usual) so they'll have to be "put together"

# first do error checking
# product_name is mandatory
set exception_count 0
set exception_text ""
if { ![info exists product_name] || [empty_string_p $product_name] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the name of the product.\n"
}
if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# categorization is a select multiple, so deal with that separately
set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0

set categorization_list [list]
while { $form_counter < $form_size} {
    if { [ns_set key $form $form_counter] == "categorization" } {
	lappend categorization_list [ns_set value $form $form_counter]
    }
    incr form_counter
}

# break categorization into category_id_list, subcategory_id_list, subsubcategory_id_list
set category_id_list [list]
set subcategory_id_list [list]
set subsubcategory_id_list [list]
foreach categorization $categorization_list {
    if ![catch {set category_id [lindex $categorization 0] } ] {
	if { [lsearch -exact $category_id_list $category_id] == -1 && ![empty_string_p $category_id]} {
	    lappend category_id_list $category_id
	}
    }
    if ![catch {set subcategory_id [lindex $categorization 1] } ] {
	if {[lsearch -exact $subcategory_id_list $subcategory_id] == -1 && ![empty_string_p $subcategory_id]} {
	    lappend subcategory_id_list $subcategory_id
	}
    }
    if ![catch {set subsubcategory_id [lindex $categorization 2] } ] {
	if {[lsearch -exact $subsubcategory_id_list $subsubcategory_id] == -1 && ![empty_string_p $subsubcategory_id] } {
	    lappend subsubcategory_id_list $subsubcategory_id
	}
    }
}

# Now deal with dates.
# The column available_date is known to be a date.
# Also, some of the custom fields may be dates.
# Unlike in add-2.tcl, some dates may be passed on as hidden form elements
# and might not be passed in parts as with the dateentry widgets.  So I'm not going
# to set them to null if the date recombination failes and the dates already exist.


set date_fields [list "available_date"]

set db [ns_db gethandle]
set additional_date_fields [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where column_type='date' and active_p='t'"]

set all_date_fields [concat $date_fields $additional_date_fields]

foreach date_field $all_date_fields {
    if [catch  { ns_dbformvalue $form $date_field date $date_field} errmsg ] {
	if { ![info exists $date_field] } {
	    set $date_field ""
	}
    }
}

# one last manipulation of data is needed: get rid of "http://" if that's all that's
# there for the url (since that was the default value)
if { [string compare $url "http://"] == 0 } {
    set url ""
}

# We now have all values in the correct form

# Get the directory where dirname is stored
set subdirectory [ec_product_file_directory $product_id]
set full_dirname "[ad_parameter EcommerceDataDirectory ecommerce][ad_parameter ProductDataDirectory ecommerce]$subdirectory/$dirname"

# if an image file has been specified, upload it into the
# directory that was just created and make a thumbnail (using
# dimensions specified in parameters/whatever.ini)

if { [info exists upload_file] && ![string compare $upload_file ""] == 0 } {
    
    # this takes the upload_file and sticks its contents into a temporary
    # file (will be deleted when the thread ends)
    set tmp_filename [ns_queryget upload_file.tmpfile]
    

    # so that we'll know if it's a gif or a jpg
    set file_extension [file extension $upload_file]

    # copies this temp file into a permanent file
    set perm_filename "$full_dirname/product$file_extension"
    ns_cp $tmp_filename $perm_filename
    
    # create thumbnails
    # thumbnails are all jpg files
    
    # set thumbnail dimensions
    if [catch {set thumbnail_width [ad_parameter ThumbnailWidth ecommerce]} ] {
	if [catch {set thumbnail_height [ad_parameter ThumbnailHeight ecommerce]} ] {
	    set convert_dimensions "100x10000"
	} else {
	    set convert_dimensions "10000x$thumbnail_height"
	}
    } else {
	set convert_dimensions "${thumbnail_width}x10000"
    }

    set perm_thumbnail_filename "$full_dirname/product-thumbnail.jpg"

    exec /usr/local/bin/convert -geometry $convert_dimensions $perm_filename $perm_thumbnail_filename
}

set linked_thumbnail [ec_linked_thumbnail_if_it_exists $dirname]

ReturnHeaders
ns_write "[ad_admin_header "Confirm Product Changes"]

<h2>Confirm Product Changes</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Products"] [list "one.tcl?[export_url_vars product_id]" $product_name] "Edit Product"]
<hr>
<h3>Please confirm that the information below is correct:</h3>
"

set currency [ad_parameter Currency ecommerce]
set multiple_retailers_p [ad_parameter MultipleRetailersPerProductP ecommerce]

ns_write "<form method=post action=edit-3.tcl>
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
SKU
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
<tr>
<td>
Available Date
</td>
<td>
[ec_message_if_null [util_AnsiDatetoPrettyDate $available_date]]
</td>
</tr>
</table>
</blockquote>
<p>

[export_form_vars product_name sku category_id_list subcategory_id_list subsubcategory_id_list one_line_description detailed_description color_list size_list style_list search_keywords url price present_p available_date shipping shipping_additional weight template_id product_id dirname stock_status]
"

# also need to export custom field values
set additional_variables_to_export [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where active_p='t'"]

foreach user_class_id [database_to_tcl_list $db "select user_class_id from ec_user_classes"] {
    lappend additional_variables_to_export "price$user_class_id"
}

eval "ns_write \"\[export_form_vars $additional_variables_to_export\]\n\""


ns_write "<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"