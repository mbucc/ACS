# $Id: edit-3.tcl,v 3.1.2.1 2000/04/28 15:08:51 carsten Exp $
set_the_usual_form_variables

# product_id, product_name, sku, category_id_list, subcategory_id_list, subsubcategory_id_list, one_line_description, detailed_description, color_list, size_list, style_list, search_keywords, url, price, present_p, available_date, shipping, shipping_additional, weight, template_id, dirname, stock_status
# the custom product fields may or may not exist
# and price$user_class_id for all the user classes may or may not exist
# (because someone may have added a user class while this product was
# being added)

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# we have to generate audit information
# First, write as insert
set audit_fields "last_modified, last_modifying_user, modified_ip_address"
set audit_info "sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]'"

# Or otherwise write as update
set audit_update "last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]'"

ns_db dml $db "begin transaction"

# we have to insert or update things in 6 tables: ec_products, ec_custom_product_field_values, 
# ec_category_product_map, ec_subcategory_product_map, ec_subsubcategory_product_map,
# ec_product_user_class_prices

ns_db dml $db "update ec_products
set product_name='$QQproduct_name', sku='$QQsku', one_line_description='$QQone_line_description', detailed_description='$QQdetailed_description', color_list='$QQcolor_list', size_list='$QQsize_list', style_list='$QQstyle_list', search_keywords='$QQsearch_keywords', url='$QQurl', price='$price', present_p='$present_p', available_date='$available_date', shipping='$shipping', shipping_additional='$shipping_additional', weight='$weight', template_id='$template_id', stock_status='$QQstock_status', $audit_update
where product_id=$product_id
"
# things to insert or update in ec_custom_product_field_values if they exist
set custom_columns [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where active_p='t'"]

if { [database_to_tcl_string $db "select count(*) from ec_custom_product_field_values where product_id=$product_id"] == 0 } {
    # then we want to insert, not update
    set custom_columns_to_insert [list product_id]
    set custom_column_values_to_insert [list $product_id]
    foreach custom_column $custom_columns {
	if {[info exists $custom_column] } {
	    lappend custom_columns_to_insert $custom_column
	    lappend custom_column_values_to_insert "'[set QQ$custom_column]'"
	}
    }

    ns_db dml $db "insert into ec_custom_product_field_values
    ([join $custom_columns_to_insert ", "], $audit_fields)
    values
    ([join $custom_column_values_to_insert ","], $audit_info)
    "

} else {
    set update_list [list]
    foreach custom_column $custom_columns {
	if {[info exists $custom_column] } {
	    lappend update_list "$custom_column='[set QQ$custom_column]'"
	}
    }

    if {[llength $update_list] > 0 } {
	ns_db dml $db "update ec_custom_product_field_values set [join $update_list ", "], $audit_update where product_id=$product_id"
    }
}

# Take care of categories and subcategories and subsubcategories.
# This is going to leave current values in the map tables, remove 
# rows no longer valid and add new rows for ids not already there.
# Because the reference constraints go from categories to subsubcategories
# first the subsubcategories to categories will be deleted, then
# new categories down to subsubcategories will be added.

# Make a list of categories, subcategories, subsubcategories in the database
set old_category_id_list [database_to_tcl_list $db "select category_id from ec_category_product_map where product_id=$product_id"]

set old_subcategory_id_list [database_to_tcl_list $db "select subcategory_id from ec_subcategory_product_map where product_id=$product_id"]

set old_subsubcategory_id_list [database_to_tcl_list $db "select subsubcategory_id from ec_subsubcategory_product_map where product_id=$product_id"]

# Delete subsubcategory maps through category maps

foreach old_subsubcategory_id $old_subsubcategory_id_list {
    if { [lsearch -exact $subsubcategory_id_list $old_subsubcategory_id] == -1 } {
	# This old subsubcategory id is not in the new list and needs
	# to be deleted
	ns_db dml $db "delete from ec_subsubcategory_product_map where product_id=$product_id and subsubcategory_id=$old_subsubcategory_id"

	# audit
	ad_audit_delete_row $db [list $old_subsubcategory_id $product_id] [list subsubcategory_id product_id] ec_subsubcat_prod_map_audit
    }
}

foreach old_subcategory_id $old_subcategory_id_list {
    if { [lsearch -exact $subcategory_id_list $old_subcategory_id] == -1 } {
	# This old subcategory id is not in the new list and needs
	# to be deleted
	ns_db dml $db "delete from ec_subcategory_product_map where product_id=$product_id and subcategory_id=$old_subcategory_id"

	# audit
	ad_audit_delete_row $db [list $old_subcategory_id $product_id] [list subcategory_id product_id] ec_subcat_prod_map_audit
    }
}

foreach old_category_id $old_category_id_list {
    if { [lsearch -exact $category_id_list $old_category_id] == -1 } {
	# This old category id is not in the new list and needs
	# to be deleted
	ns_db dml $db "delete from ec_category_product_map where product_id=$product_id and category_id=$old_category_id"

	# audit
	ad_audit_delete_row $db [list $old_category_id $product_id] [list category_id product_id] ec_category_product_map_audit
    }
}

# Now add categorization maps

foreach new_category_id $category_id_list {
    if { [lsearch -exact $old_category_id_list $new_category_id] == -1 } {
	# The new category id is not an existing category mapping
	# so add it.
	ns_db dml $db "insert into ec_category_product_map (product_id, category_id, $audit_fields) values ($product_id, $new_category_id, $audit_info)"
    }
}

foreach new_subcategory_id $subcategory_id_list {
    if { [lsearch -exact $old_subcategory_id_list $new_subcategory_id] == -1 } {
	# The new subcategory id is not an existing subcategory mapping
	# so add it.
	ns_db dml $db "insert into ec_subcategory_product_map (product_id, subcategory_id, $audit_fields) values ($product_id, $new_subcategory_id, $audit_info)"
    }
}

foreach new_subsubcategory_id $subsubcategory_id_list {
    if { [lsearch -exact $old_subsubcategory_id_list $new_subsubcategory_id] == -1 } {
	# The new subsubcategory id is not an existing subsubcategory mapping
	# so add it.
	ns_db dml $db "insert into ec_subsubcategory_product_map (product_id, subsubcategory_id, $audit_fields) values ($product_id, $new_subsubcategory_id, $audit_info)"
    }
}

# Take care of special prices for user classes
# First get a list of old user_class_id values and a list of all 
# user_class_id values.
# Then delete a user_class_price if its ID does not exist or value is empty.
# Last go through all user_class_id values and add the user_class_price
# if it is not in the old user_class_id_list
set all_user_class_id_list [database_to_tcl_list $db "select user_class_id from ec_user_classes"]

set old_user_class_id_list [list]
set old_user_class_price_list [list]
set selection [ns_db select $db "select user_class_id, price from ec_product_user_class_prices where product_id=$product_id"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend old_user_class_id_list $user_class_id
    lappend old_user_class_price_list [ns_dbquotevalue $price]
}

# Counter is used to find the corresponding user_class_price for the current
# user_class_id
set counter 0
foreach user_class_id $old_user_class_id_list {
    if { ![info exists price$user_class_id] || [empty_string_p [set price$user_class_id]] } {
	# This old user_class_id does not have a value, so delete it

	ns_db dml $db "delete from ec_product_user_class_prices where user_class_id = $user_class_id"

	# audit
	ad_audit_delete_row $db [list $user_class_id [lindex $old_user_class_price_list $counter] $product_id] [list user_class_id price product_id] ec_product_u_c_prices_audit
    }
    incr counter
}

# Add new values
foreach user_class_id $all_user_class_id_list {
    if { [info exists price$user_class_id] } {
	# This user_class_id exists and must either be inserted
	# or updated if its value has changed.

	set index [lsearch -exact $old_user_class_id_list $user_class_id]
	if { $index == -1 } {
	    # This user_class_id exists and is not in the 
	    ns_db dml $db "insert into ec_product_user_class_prices (product_id, user_class_id, price, $audit_fields) values ($product_id, $user_class_id, '[set price$user_class_id]', $audit_info)"
	} else {
	    # Check if user_class_price has changed
	    if { [set price$user_class_id] != [lindex $old_user_class_price_list $index] } {
		ns_db dml $db "update ec_product_user_class_prices set price='[set price$user_class_id]', $audit_update where user_class_id = $user_class_id and product_id = $product_id"
	    }
	}
    }
}

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?product_id=$product_id"
return