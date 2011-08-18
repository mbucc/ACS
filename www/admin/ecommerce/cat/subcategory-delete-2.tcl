# $Id: subcategory-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:35 carsten Exp $
set_the_usual_form_variables
# subcategory_id

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars subcategory_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# What has to be done (in order, so that no constraints are violated):
# 1. remove the rows in ec_subsubcategory_product_map where the subsubcategory_ids
# share a row with $subcategory_id in ec_subsubcategories
# 2. remove those rows in ec_subsubcategories
# 3. remove the rows in ec_subcategory_product_map where the subcategory_id is
# $subcategory_id
# 4. remove the row in ec_subcategories where subcategory_id = $subcategory_id

# So, here goes:

set db [ns_db gethandle]
ns_db dml $db "begin transaction"

# 1. remove the rows in ec_subsubcategory_product_map where the subsubcategory_ids
# share a row with $subcategory_id in ec_subsubcategories

set subsubcategory_list [database_to_tcl_list $db "select subsubcategory_id from ec_subsubcategories where subcategory_id=$subcategory_id"]

ns_db dml $db "delete from ec_subsubcategory_product_map 
where subsubcategory_id in (select subsubcategory_id from ec_subsubcategories where subcategory_id=$subcategory_id)"

# audit table
foreach subsubcategory $subsubcategory_list {
    ad_audit_delete_row $db [list $subsubcategory] [list subsubcategory_id] ec_subsubcat_prod_map_audit
}

# 2. remove those rows in ec_subsubcategories

ns_db dml $db "delete from ec_subsubcategories where subcategory_id=$subcategory_id"

# audit table
foreach subsubcategory $subsubcategory_list {
    ad_audit_delete_row $db [list $subsubcategory] [list subsubcategory_id] ec_subsubcategories_audit
}

# 3. remove the rows in ec_subcategory_product_map where the subcategory_id is
# $subcategory_id

ns_db dml $db "delete from ec_subcategory_product_map where subcategory_id=$subcategory_id"

# audit table
ad_audit_delete_row $db [list $subcategory_id] [list subcategory_id] ec_subcat_prod_map_audit

# 4. remove the row in ec_subcategories where subcategory_id = $subcategory_id

ns_db dml $db "delete from ec_subcategories where subcategory_id=$subcategory_id"

# audit table
ad_audit_delete_row $db [list $subcategory_id] [list subcategory_id] ec_subcategories_audit

ns_db dml $db "end transaction"

ad_returnredirect "index.tcl"