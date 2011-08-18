# $Id: sale-price-expire-2.tcl,v 3.0.4.1 2000/04/28 15:08:54 carsten Exp $
set_the_usual_form_variables
# product_id, product_name, sale_price_id

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]
ns_db dml $db "update ec_sale_prices set sale_ends=sysdate, last_modified=sysdate, last_modifying_user=$user_id, modified_ip_address='[DoubleApos [ns_conn peeraddr]]' where sale_price_id=$sale_price_id"

ad_returnredirect "sale-prices.tcl?[export_url_vars product_id product_name]"
