# $Id: subsubcategory-property-toggle.tcl,v 3.0.4.1 2000/04/28 15:08:54 carsten Exp $
set_the_usual_form_variables
# product_id and publisher_favorite_p
# and, for the purpose of redirecting back, category_id, category_name, subcategory_id, subcategory_name, subsubcategory_id, subsubcategory_name

if { [info exists publisher_favorite_p] && ![empty_string_p $publisher_favorite_p] } {
    set thing_to_update "publisher_favorite_p='$publisher_favorite_p'"
}


if { ![info exists thing_to_update] } {
    ad_return_complaint 1 "<li>No column to update has been specified.\n"
}

set db [ns_db gethandle]
ns_db dml $db "update ec_subsubcategory_product_map
set $thing_to_update
where product_id=$product_id"

ad_returnredirect one-subsubcategory.tcl?[export_url_vars category_id category_name subcategory_id subcategory_name subsubcategory_id subsubcategory_name]
