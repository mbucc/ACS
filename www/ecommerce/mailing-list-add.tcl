# $Id: mailing-list-add.tcl,v 3.0.4.1 2000/04/28 15:10:01 carsten Exp $
set_the_usual_form_variables
# category_id, subcategory_id, and/or subsubcategory_id
# (if subcategory_id exists, then category_id should exist;
# if subsubcategory_id exists, then subcategory_id and
# category_id should exist)

# possibly usca_p

# this page either redirects them to log on or asks them to confirm that
# they are who we think they are

set user_id [ad_verify_and_get_user_id]

set return_url "[ad_parameter EcommercePath ecommerce]mailing-list-add-2.tcl?[export_url_vars category_id subcategory_id subsubcategory_id]"

if {$user_id == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary [export_entire_form_as_url_vars]
# type2

ec_log_user_as_user_id_for_this_session

set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name as user_name from users where user_id=$user_id"]

# if { [info exists category_id] } {
#     set mailing_list_name [database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]
# } elseif { [info exists subcategory_id] } {
#     set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]"
# } elseif { [info exists subsubcategory_id] } {
#     set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]: [database_to_tcl_string $db "select subsubcategory_name from ec_subsubcategories where subsubcategory_id=$subsubcategory_id"]"
# } else {
#     ad_return_complaint 1 "You haven't specified which mailing list you want to be added to."
#     return
# }

if { ![info exists subcategory_id] || [empty_string_p $subcategory_id] } {
    set mailing_list_name [database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]
} elseif { ![info exists subsubcategory_id] || [empty_string_p $subsubcategory_id] } {
    set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]"
} elseif { [info exists subsubcategory_id] && ![empty_string_p $subsubcategory_id] } {
    set mailing_list_name "[database_to_tcl_string $db "select category_name from ec_categories where category_id=$category_id"]: [database_to_tcl_string $db "select subcategory_name from ec_subcategories where subcategory_id=$subcategory_id"]: [database_to_tcl_string $db "select subsubcategory_name from ec_subsubcategories where subsubcategory_id=$subsubcategory_id"]"
} else {
    ad_return_complaint 1 "You haven't specified which mailing list you want to be added to."
    return
}


set register_link "/register.tcl?[export_url_vars return_url]"
set hidden_form_variables [export_form_vars category_id subcategory_id subsubcategory_id]

ad_return_template