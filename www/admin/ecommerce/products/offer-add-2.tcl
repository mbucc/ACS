# $Id: offer-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:52 carsten Exp $
set_the_usual_form_variables
# offer_id, product_id, product_name, retailer_id, price, shipping, stock_status,
# offer_begins, offer_ends, special_offer_p, special_offer_html
# and possibly shipping_unavailable_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# see if an offer with this offer_id exists, meaning they pushed
# submit twice

if { [database_to_tcl_string $db "select count(*) from ec_offers where offer_id=$offer_id"] > 0 } {
    ad_returnredirect "offers.tcl?[export_url_vars product_id product_name]"
    return
}

if { [info exists shipping_unavailable_p] } {
    set additional_column ", shipping_unavailable_p"
    set additional_value ", 't'"
} else {
    set additional_column ""
    set additional_value ""
}

ns_db dml $db "insert into ec_offers
(offer_id, product_id, retailer_id, price, shipping, stock_status, special_offer_p, special_offer_html, offer_begins, offer_ends $additional_column, last_modified, last_modifying_user, modified_ip_address)
values
($offer_id, $product_id, $retailer_id, '$QQprice', '$QQshipping', '$QQstock_status', '$special_offer_p','$QQspecial_offer_html', to_date('$offer_begins','YYYY-MM-DD HH24:MI:SS'), to_date('$offer_ends','YYYY-MM-DD HH24:MI:SS') $additional_value, sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')
"

ad_returnredirect "offers.tcl?[export_url_vars product_id product_name]"
