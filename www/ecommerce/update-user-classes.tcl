# $Id: update-user-classes.tcl,v 3.0.4.1 2000/04/28 15:10:04 carsten Exp $
set_form_variables 0
# possibly usca_p

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set user_session_id [ec_get_user_session_id]

set db_pools [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_pools 0]
set db_sub [lindex $db_pools 1]
ec_create_new_session_if_necessary
# type1

ec_log_user_as_user_id_for_this_session

# two variables for the ADP page
set user_classes_need_approval [ad_parameter UserClassApproveP ecommerce]

set user_class_select_list [ec_user_class_select_widget $db [database_to_tcl_list $db "select user_class_id from ec_user_class_user_map where user_id = $user_id"]]

ad_return_template

