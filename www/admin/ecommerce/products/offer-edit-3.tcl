# $Id: offer-edit-3.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
set_the_usual_form_variables
# offer_id, product_id, product_name, retailer_id, price, shipping, stock_status, old_retailer_id, offer_begins, offer_ends, 
# special_offer_p, special_offer_html
# and possibly shipping_unavailable_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

if { [info exists shipping_unavailable_p] } {
    set additional_thing_to_insert ", shipping_unavailable_p='t'"
} else {
    set additional_thing_to_insert ", shipping_unavailable_p='f'"
}

ns_db dml $db "update ec_offers
set retailer_id=$retailer_id, price='$QQprice', shipping='$QQshipping', stock_status='$QQstock_status', special_offer_p='$special_offer_p', special_offer_html='$QQspecial_offer_html', offer_begins=to_date('$offer_begins','YYYY-MM-DD HH24:MI:SS'), offer_ends=to_date('$offer_ends','YYYY-MM-DD HH24:MI:SS') $additional_thing_to_insert, last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]'
where offer_id=$offer_id"

ad_returnredirect "offers.tcl?[export_url_vars product_id product_name]"
