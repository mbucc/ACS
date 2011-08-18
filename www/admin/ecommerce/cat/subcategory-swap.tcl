# $Id: subcategory-swap.tcl,v 3.0.4.1 2000/04/28 15:08:36 carsten Exp $
set_the_usual_form_variables
# subcategory_id, next_subcategory_id, sort_key, next_sort_key, category_id, category_name

# switches the ordering of a category with that of the next subcategory

set db [ns_db gethandle]

set item_match [database_to_tcl_string $db "select count(*) from ec_subcategories where subcategory_id=$subcategory_id and sort_key=$sort_key"]

set next_item_match [database_to_tcl_string $db "select count(*) from ec_subcategories where subcategory_id=$next_subcategory_id and sort_key=$next_sort_key"]

if { $item_match != 1 || $next_item_match != 1 } {
    ad_return_complaint 1 "<li>The page you came from appears to be out-of-date;
    perhaps someone has changed the subcategories since you last reloaded the page.
    Please go back to the previous page, push \"reload\" or \"refresh\" and try
    again."
    return
}

ns_db dml $db "begin transaction"
ns_db dml $db "update ec_subcategories set sort_key=$next_sort_key where subcategory_id=$subcategory_id"
ns_db dml $db "update ec_subcategories set sort_key=$sort_key where subcategory_id=$next_subcategory_id"
ns_db dml $db "end transaction"

ad_returnredirect "category.tcl?[export_url_vars category_id category_name]"