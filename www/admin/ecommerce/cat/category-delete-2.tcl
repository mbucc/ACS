# $Id: category-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:35 carsten Exp $
set_the_usual_form_variables
# category_id

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars category_name category_id subcategory_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# What has to be done (in order, so that no constraints are violated):
# 1. remove the rows in ec_subsubcategory_product_map where the 
# subsubcategory_ids share a row with the subcategory_ids that share a
# row with $category_id in ec_subcategories
# 2. remove those rows in ec_subsubcategories
# 3. remove the rows in ec_subcategory_product_map where the subcategory_ids
# share a row with $category_id in ec_subcategories
# 4. remove those rows in ec_subcategories
# 5. remove the rows in ec_category_product_map where the category_id is
# $category_id
# 6. remove the rows in ec_category_template_map where the category_id is
# $category_id
# 7. remove the row in ec_categories where category_id = $category_id

# So, here goes:

set db [ns_db gethandle]
ns_db dml $db "begin transaction"

# 1. remove the rows in ec_subsubcategory_product_map where the 
# subsubcategory_ids share a row with the subcategory_ids that share a
# row with $category_id in ec_subcategories

set subsubcategory_list [database_to_tcl_list $db "select subsubcategory_id from ec_subsubcategories where subcategory_id in (select subcategory_id from ec_subcategories where category_id=$category_id)"]

set subcategory_list [database_to_tcl_list $db "select subcategory_id from ec_subcategories where category_id=$category_id"]

ns_db dml $db "delete from ec_subsubcategory_product_map 
where subsubcategory_id in (select subsubcategory_id from ec_subsubcategories where subcategory_id in (select subcategory_id from ec_subcategories where category_id=$category_id))"

# audit table
foreach subsubcategory $subsubcategory_list {
    ad_audit_delete_row $db [list $subsubcategory] [list subsubcategory_id] ec_subsubcat_prod_map_audit
}

# 2. remove those rows in ec_subsubcategories

ns_db dml $db "delete from ec_subsubcategories where subcategory_id in (select subcategory_id from ec_subcategories where category_id=$category_id)"

# audit table
foreach subsubcategory $subsubcategory_list {
    ad_audit_delete_row $db [list $subsubcategory] [list subsubcategory_id] ec_subsubcategories_audit
}

# 3. remove the rows in ec_subcategory_product_map where the subcategory_ids
# share a row with $category_id in ec_subcategories

ns_db dml $db "delete from ec_subcategory_product_map
where subcategory_id in (select subcategory_id from ec_subcategories where category_id=$category_id)"

# audit table
foreach subcategory $subcategory_list {
    ad_audit_delete_row $db [list $subcategory] [list subcategory_id] ec_subcat_prod_map_audit
}

# 4. remove those rows in ec_subcategories

ns_db dml $db "delete from ec_subcategories where category_id=$category_id"

foreach subcategory $subcategory_list {
    ad_audit_delete_row $db [list $subcategory] [list subcategory_id] ec_subcategories_audit
}

# 5. remove the rows in ec_category_product_map where the category_id is
# $category_id

ns_db dml $db "delete from ec_category_product_map where category_id=$category_id"
ad_audit_delete_row $db [list $category_id] [list category_id] ec_category_product_map_audit

# 6. remove the rows in ec_category_template_map where the category_id is
# $category_id

ns_db dml $db "delete from ec_category_template_map where category_id=$category_id"

## no audit table associated with this one

# 7. remove the row in ec_categories where category_id = $category_id

ns_db dml $db "delete from ec_categories where category_id=$category_id"
ad_audit_delete_row $db [list $category_id] [list category_id] ec_categories_audit

ns_db dml $db "end transaction"

ad_returnredirect "index.tcl"