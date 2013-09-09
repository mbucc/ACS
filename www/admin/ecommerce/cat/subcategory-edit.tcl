# /www/admin/ecommerce/cat/subcategory-edit.tcl
ad_page_contract {

    Updates name od ecommerce product subcategory.

    @param category_name the name of the category
    @param category_id the ID of the category
    @param subcategory_id the ID of this subcategory
    @param subcategory the new name of this subcategory

    @cvs-id subcategory-edit.tcl,v 3.2.2.7 2000/08/28 21:06:19 hbrock Exp
} {
    category_name:trim,notnull
    category_id:notnull,integer
    subcategory_id:notnull,integer
    subcategory_name:trim,notnull
}


# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]?[export_url_vars category_name category_id subcategory_id subcategory_name]"

    ad_returnredirect "/register?[export_url_vars return_url]"
    return
}

set address [ns_conn peeraddr]

db_dml update_ec_subcats "update ec_subcategories
set subcategory_name=:subcategory_name,
last_modified=sysdate,
last_modifying_user=:user_id,
modified_ip_address=:address
where subcategory_id=:subcategory_id"
db_release_unused_handles
ad_returnredirect "subcategory?[export_url_vars category_id category_name subcategory_id subcategory_name]"



