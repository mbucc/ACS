# $Id: shopping-cart-save.tcl,v 3.0.4.1 2000/04/28 15:10:04 carsten Exp $
# this page either redirects them to log on or asks them to confirm that
# they are who we think they are

set user_id [ad_verify_and_get_user_id]

set return_url "[ad_parameter EcommercePath ecommerce]shopping-cart-save-2.tcl"

if {$user_id == 0} {
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name as user_name from users where user_id=$user_id"]
set register_link "/register.tcl?[export_url_vars return_url]"

ad_return_template