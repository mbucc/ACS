# $Id: delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:50 carsten Exp $
set_the_usual_form_variables
# product_id, product_name

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars product_id product_name]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# cannot delete if there is an order which has this product, i.e. if
# this product exists in:
# ec_items

# have to delete from:
# ec_offers
# ec_custom_product_field_values
# ec_subsubcategory_product_map
# ec_subcategory_product_map
# ec_category_product_map
# ec_product_reviews
# ec_product_comments
# ec_product_links
# ec_product_user_class_prices
# ec_product_series_map
# ec_products

set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from ec_items where product_id=$product_id"] > 0 } {
    ns_return 200 text/html "[ad_admin_header "Sorry"]\nSorry, you cannot delete a product for which an order has already been made.  Instead, you can <a href=\"toggle-active-p.tcl?[export_url_vars product_id product_name]&active_p=f\">Mark It Inactive</a>, which will make it no longer show up in the consumer pages."
    return
}

ns_db dml $db "begin transaction"

# 1. Offers
set offer_list [database_to_tcl_list $db "select offer_id from ec_offers where product_id=$product_id"]

ns_db dml $db "delete from ec_offers where product_id=$product_id"

# audit
foreach offer_id $offer_list {
    ad_audit_delete_row $db [list $offer_id $product_id] [list offer_id product_id] ec_offers_audit
}

# 2. Custom Product Field Values
ns_db dml $db "delete from ec_custom_product_field_values where product_id=$product_id"
ad_audit_delete_row $db [list $product_id] [list product_id] ec_custom_p_field_values_audit

# 3. Subsubcategory Product map
set subsubcategory_list [database_to_tcl_list $db "select subsubcategory_id from ec_subsubcategory_product_map where product_id=$product_id"]

ns_db dml $db "delete from ec_subsubcategory_product_map where product_id=$product_id"

# audit
foreach subsubcategory_id $subsubcategory_list {
    ad_audit_delete_row $db [list $subsubcategory_id $product_id] [list subsubcategory_id product_id] ec_subsubcat_prod_map_audit
}

# 4. Subcategory Product map
set subcategory_list [database_to_tcl_list $db "select subcategory_id from ec_subcategory_product_map where product_id=$product_id"]

ns_db dml $db "delete from ec_subcategory_product_map where product_id=$product_id"

# audit
foreach subcategory_id $subcategory_list {
    ad_audit_delete_row $db [list $subcategory_id $product_id] [list subcategory_id product_id] ec_subcat_prod_map_audit
}

# 5. Category Product map
set category_list [database_to_tcl_list $db "select category_id from ec_category_product_map where product_id=$product_id"]

ns_db dml $db "delete from ec_category_product_map where product_id=$product_id"

# audit
foreach category_id $category_list {
    ad_audit_delete_row $db [list $category_id $product_id] [list category_id product_id] ec_category_product_map_audit
}

# 6. Product Reviews
set review_list [database_to_tcl_list $db "select review_id from ec_product_reviews where product_id=$product_id"]

ns_db dml $db "delete from ec_product_reviews where product_id=$product_id"

# audit
foreach review_id $review_list {
    ad_audit_delete_row $db [list $review_id $product_id] [list review_id product_id] ec_product_reviews_audit
}

# 7. Product Comments
ns_db dml $db "delete from ec_product_comments where product_id=$product_id"

# comments aren't audited

# 8. Product Relationship Links
set product_a_list [database_to_tcl_list $db "select product_a from ec_product_links where product_b=$product_id"]
set product_b_list [database_to_tcl_list $db "select product_b from ec_product_links where product_a=$product_id"]

ns_db dml $db "delete from ec_product_links where product_a=$product_id or product_b=$product_id"

# audit
foreach product_a $product_a_list {
    ad_audit_delete_row $db [list $product_a $product_id] [list product_a product_id] ec_product_links_audit
}
foreach product_b $product_b_list {
    ad_audit_delete_row $db [list $product_b $product_id] [list product_b product_id] ec_product_links_audit
}

# 9. User Class
set user_class_id_list [list]
set user_class_price_list [list]
set selection [ns_db select $db "select user_class_id, price from ec_product_user_class_prices where product_id=$product_id"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    lappend user_class_id_list $user_class_id
    lappend user_class_price_list $price
}

ns_db dml $db "delete from ec_product_user_class_prices where product_id=$product_id"

# audit
set counter 0
foreach user_class_id $user_class_id_list {
    ad_audit_delete_row $db [list $user_class_id [lindex $user_class_price_list $counter] $product_id] [list user_class_id price product_id] ec_product_u_c_prices_audit
    incr counter
}

# 10. Product Series map
set series_id_list [database_to_tcl_list $db "select series_id from ec_product_series_map where component_id=$product_id"]
set component_id_list [database_to_tcl_list $db "select component_id from ec_product_series_map where series_id=$product_id"]

ns_db dml $db "delete from ec_product_series_map where series_id=$product_id or component_id=$product_id"

# audit
foreach series_id $series_id_list {
    ad_audit_delete_row $db [list $series_id $product_id] [list series_id component_id] ec_product_series_map_audit
}
foreach component_id $component_id_list {
    ad_audit_delete_row $db [list $product_id $component_id] [list series_id component_id] ec_product_series_map_audit
}

# 11. Products
ns_db dml $db "delete from ec_products where product_id=$product_id"

# audit
ad_audit_delete_row $db [list $product_id] [list product_id] ec_products_audit

ns_db dml $db "end transaction"

ad_returnredirect "index.tcl"
