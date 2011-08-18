# $Id: subsubcategory-delete-2.tcl,v 3.0.4.1 2000/04/28 15:08:36 carsten Exp $
set_the_usual_form_variables
# subsubcategory_id, subcategory_id, subcategory_name, category_id, category_name

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars category_name category_id subcategory_id subcategory_name subsubcategory_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# What has to be done (in order, so that no constraints are violated):
# 1. remove the rows in ec_subsubcategory_product_map where subsubcategory_id
# is $subsubcategory_id
# 2. remove the row in ec_subsubcategories where subsubcategory_id = $subsubcategory_id

# So, here goes:

set db [ns_db gethandle]
ns_db dml $db "begin transaction"

# 1. remove the rows in ec_subsubcategory_product_map where subsubcategory_id
# is $subsubcategory_id

ns_db dml $db "delete from ec_subsubcategory_product_map where subsubcategory_id=$subsubcategory_id"

# audit table
ad_audit_delete_row $db [list $subsubcategory_id] [list subsubcategory_id] ec_subsubcat_prod_map_audit

# 2. remove the row in ec_subsubcategories where subsubcategory_id = $subsubcategory_id

ns_db dml $db "delete from ec_subsubcategories where subsubcategory_id = $subsubcategory_id"

# audit table
ad_audit_delete_row $db [list $subsubcategory_id] [list subsubcategory_id] ec_subsubcategories_audit

ns_db dml $db "end transaction"

ad_returnredirect "subcategory.tcl?[export_url_vars subcategory_id subcategory_name category_id category_name]"
