# $Id: mailing-list-remove.tcl,v 3.1.2.1 2000/04/28 15:10:01 carsten Exp $
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


set delete_string "delete from ec_cat_mailing_lists where user_id=$user_id"

if { [info exists category_id] && ![empty_string_p $category_id] } {
    append delete_string " and category_id=$category_id"
    set mailing_list_name [database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]

} else {
    append delete_string " and category_id is null"
}

if { [info exists subcategory_id] && ![empty_string_p $subcategory_id] } {

    append delete_string " and subcategory_id=$subcategory_id"
    set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]"

} else {
    append delete_string " and subcategory_id is null"
}
 

if { [info exists subsubcategory_id] && ![empty_string_p $subsubcategory_id] } {

    append delete_string " and subsubcategory_id=$subsubcategory_id"
    set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]: [database_to_tcl_string $db "select subsubcategory_name from ec_subsubcategories where subsubcategory_id=$subsubcategory_id"]"

} else {
    append delete_string " and subsubcategory_id is null"
}

if { ![info exists mailing_list_name] } {
    ad_return_complaint 1 "You haven't specified which mailing list you want to be removed from."
    return
}

ns_db dml $db $delete_string

set re_add_link "<a href=\"mailing-list-add.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]\">[ec_insecure_url][ad_parameter EcommercePath ecommerce]mailing-list-add.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]</a>"

set back_to_account_link "<a href=\"[ec_insecure_url][ad_parameter EcommercePath ecommerce]account.tcl\">Your Account</a>"

set continue_shopping_options [ec_continue_shopping_options $db]

ad_return_template