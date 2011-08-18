# $Id: add-4.tcl,v 3.1.2.1 2000/04/28 15:08:47 carsten Exp $
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

# make sure this product isn't already in the database (implying they pushed reload)
if { [database_to_tcl_string $db "select count(*) from ec_products where product_id=$product_id"] > 0 } {
    ad_returnredirect "one.tcl?[export_url_vars product_id]"
    return
}

set user_class_id_list [database_to_tcl_list $db "select user_class_id from ec_user_classes"]

ns_db dml $db "begin transaction"

# we have to insert things into 6 tables: ec_products, ec_custom_product_field_values, 
# ec_category_product_map, ec_subcategory_product_map, ec_subsubcategory_product_map,
# ec_product_user_class_prices

# we have to generate audit information
set audit_fields "last_modified, last_modifying_user, modified_ip_address"
set audit_info "sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]'"

ns_db dml $db "insert into ec_products
(product_id, product_name, sku, one_line_description, detailed_description, color_list, size_list, style_list, search_keywords, url, price, present_p, available_date, shipping, shipping_additional, weight, template_id, dirname, active_p, stock_status, $audit_fields)
values
($product_id, '$QQproduct_name', '$QQsku', '$QQone_line_description', '$QQdetailed_description', '$QQcolor_list', '$QQsize_list', '$QQstyle_list', '$QQsearch_keywords', '$QQurl', '$price', '$present_p', '$available_date', '$shipping', '$shipping_additional', '$weight', '$template_id', '$dirname', 't', '$QQstock_status', $audit_info)
"

# things to insert into ec_custom_product_field_values if they exist
set custom_columns [database_to_tcl_list $db "select field_identifier from ec_custom_product_fields where active_p='t'"]
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

# Take care of categories and subcategories and subsubcategories
foreach category_id $category_id_list {
    ns_db dml $db "
    insert into ec_category_product_map (
     product_id, category_id, $audit_fields) values (
     $product_id, $category_id, $audit_info)"
}

foreach subcategory_id $subcategory_id_list {
    ns_db dml $db "
    insert into ec_subcategory_product_map (
     product_id, subcategory_id, $audit_fields) values (
     $product_id, $subcategory_id, $audit_info)"
}

foreach subsubcategory_id $subsubcategory_id_list {
    ns_db dml $db "
    insert into ec_subsubcategory_product_map (
     product_id, subsubcategory_id, $audit_fields) values (
     $product_id, $subsubcategory_id, $audit_info)"
}

# Take care of special prices for user classes
foreach user_class_id $user_class_id_list {
    if { [info exists price$user_class_id] } {
	ns_db dml $db "
	insert into ec_product_user_class_prices (
	 product_id, user_class_id, price, $audit_fields) values (
	 $product_id, $user_class_id, '[set price$user_class_id]', $audit_info)"
    }
}

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars product_id]"
