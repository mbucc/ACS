# $Id: thank-you.tcl,v 3.0.4.1 2000/04/28 15:10:04 carsten Exp $
set_form_variables 0
# possibly usca_p

# This is a "thank you for your order" page
# displays order summary for the most recently confirmed order for this user

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary
# type1

ec_log_user_as_user_id_for_this_session

# their most recently confirmed order (or the empty string if there is none)
set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_id=$user_id and confirmed_date is not null and order_id=(select max(o2.order_id) from ec_orders o2 where o2.user_id=$user_id and o2.confirmed_date is not null)"]

if { [empty_string_p $order_id] } {
    ad_returnredirect index.tcl
    return
}

set order_summary [ec_order_summary_for_customer $db $order_id $user_id]

ad_return_template

