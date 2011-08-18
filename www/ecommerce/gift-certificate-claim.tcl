# $Id: gift-certificate-claim.tcl,v 3.0.4.1 2000/04/28 15:10:00 carsten Exp $
# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# make sure they have an in_basket order and a user_session_id;
# this will make it more annoying for someone who just wants to
# come to this page and try random number after random number

set user_session_id [ec_get_user_session_id]

if { $user_session_id == 0 } {
    ad_returnredirect "index.tcl"
    return
}

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]
if { [empty_string_p $order_id] } {
    ad_returnredirect "index.tcl"
    return
}

ad_return_template
