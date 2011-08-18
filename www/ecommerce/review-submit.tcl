# $Id: review-submit.tcl,v 3.0.4.1 2000/04/28 15:10:02 carsten Exp $
set_the_usual_form_variables
# product_id
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars product_id prev_page_url prev_args_list]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary [export_entire_form_as_url_vars]
# type2

ec_log_user_as_user_id_for_this_session

set product_name [database_to_tcl_string $db "select product_name from ec_products where product_id=$product_id"]
lappend altered_prev_args_list $product_name

set rating_widget [ec_rating_widget]

ad_return_template