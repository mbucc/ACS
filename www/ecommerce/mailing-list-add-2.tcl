# $Id: mailing-list-add-2.tcl,v 3.1.2.1 2000/04/28 15:10:01 carsten Exp $
set_the_usual_form_variables
# category_id, subcategory_id, and/or subsubcategory_id
# possibly usca_p

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_form_vars category_id subcategory_id subsubcategory_id]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary [export_entire_form_as_url_vars]
# type2

if { ![info exists subcategory_id] || [empty_string_p $subcategory_id] } {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and category_id=$category_id and subcategory_id is null"
    set insert_string "insert into ec_cat_mailing_lists (user_id, category_id) values ($user_id, $category_id)"
    set mailing_list_name [database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]
} elseif { ![info exists subsubcategory_id] || [empty_string_p $subsubcategory_id] } {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and subcategory_id=$subcategory_id and subsubcategory_id is null"
    set insert_string "insert into ec_cat_mailing_lists (user_id, category_id, subcategory_id) values ($user_id, $category_id, $subcategory_id)"
    set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]"
} elseif { [info exists subsubcategory_id] && ![empty_string_p $subsubcategory_id] } {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and subsubcategory_id=$subsubcategory_id"
    set insert_string "insert into ec_cat_mailing_lists (user_id, category_id, subcategory_id, subsubcategory_id) values ($user_id, $category_id, $subcategory_id, $subsubcategory_id)"
    set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]: [database_to_tcl_string $db "select subsubcategory_name from ec_subsubcategories where subsubcategory_id=$subsubcategory_id"]"
} else {
    set check_string "select count(*) from ec_cat_mailing_lists where user_id=$user_id and category_id is null"
    set insert_string "insert into ec_cat_mailing_lists (user_id) values ($user_id)"
}

if { [database_to_tcl_string $db $check_string] == 0 } {
    ns_db dml $db $insert_string
}

set remove_link "<a href=\"mailing-list-remove.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]\">[ec_insecure_url][ad_parameter EcommercePath ecommerce]mailing-list-remove.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]</a>"

set continue_shopping_options [ec_continue_shopping_options $db]

ad_return_template