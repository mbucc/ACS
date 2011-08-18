# $Id: gift-certificate-order.tcl,v 3.1 2000/03/07 03:52:09 eveander Exp $
# describes gift certificates and presents a link to order a gift certificate

set system_name [ad_system_name]
set expiration_time [ec_decode [ad_parameter GiftCertificateMonths ecommerce] "12" "1 year" "24" "2 years" "[ad_parameter GiftCertificateMonths ecommerce] months"]
set minimum_amount [ec_pretty_price [ad_parameter MinGiftCertificateAmount ecommerce]]
set maximum_amount [ec_pretty_price [ad_parameter MaxGiftCertificateAmount ecommerce]]

if { [ad_ssl_available_p] } {
    set order_url "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]/ecommerce/gift-certificate-order-2.tcl"
} else {
    set order_url "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]/ecommerce/gift-certificate-order-2.tcl"
}

set db [ns_db gethandle]
ad_return_template