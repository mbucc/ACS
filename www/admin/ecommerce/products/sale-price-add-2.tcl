# $Id: sale-price-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:53 carsten Exp $
set_the_usual_form_variables
# sale_price_id product_id product_name sale_price sale_name sale_begins sale_ends offer_code

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# see if a sale price with this sale_price_id exists, meaning they pushed
# submit twice

if { [database_to_tcl_string $db "select count(*) from ec_sale_prices where sale_price_id=$sale_price_id"] > 0 } {
    ad_returnredirect "sale-prices.tcl?[export_url_vars product_id product_name]"
}

ns_db dml $db "insert into ec_sale_prices
(sale_price_id, product_id, sale_price, sale_begins, sale_ends, sale_name, offer_code, last_modified, last_modifying_user, modified_ip_address)
values
($sale_price_id, $product_id, $sale_price, to_date('$sale_begins','YYYY-MM-DD HH24:MI:SS'), to_date('$sale_ends','YYYY-MM-DD HH24:MI:SS'), '$QQsale_name', '$QQoffer_code', sysdate, $user_id, '[DoubleApos [ns_conn peeraddr]]')"

ad_returnredirect "sale-prices.tcl?[export_url_vars product_id product_name]"
