# $Id: shipping-address-international.tcl,v 3.0.4.1 2000/04/28 15:10:03 carsten Exp $
set_form_variables 0
# possibly usca_p

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

set user_name_with_quotes_escaped [philg_quote_double_quotes [database_to_tcl_string $db "select first_names || ' ' || last_name as name from users where user_id=$user_id"]]

set country_widget [ec_country_widget $db ""]

ad_return_template