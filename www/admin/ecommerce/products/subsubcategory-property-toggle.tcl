# subsubcategory-property-toggle.tcl

ad_page_contract {  
    @param product_id
    @param publisher_favorite_p
    @param category_id
    @param category_name
    @param subcategory_id
    @param subcategory_name
    @param subsubcategory_id
    @param subsubcategory_name

    @author
    @creation-date
    @cvs-id subsubcategory-property-toggle.tcl,v 3.2.2.3 2000/07/21 03:57:02 ron Exp
} {
    product_id
    publisher_favorite_p
    category_id
    category_name
    subcategory_id
    subcategory_name
    subsubcategory_id
    subsubcategory_name
}



if { [info exists publisher_favorite_p] && ![empty_string_p $publisher_favorite_p] } {
    set thing_to_update "publisher_favorite_p=:publisher_favorite_p"
}

if { ![info exists thing_to_update] } {
    ad_return_complaint 1 "<li>No column to update has been specified.\n"
}


db_dml update_subsub_product_map "update ec_subsubcategory_product_map
set $thing_to_update
where product_id=:product_id"
db_release_unused_handles
ad_returnredirect one-subsubcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name subsubcategory_id subsubcategory_name]

