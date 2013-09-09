#  www/ecommerce/gift-certificate-order.tcl
ad_page_contract {
 describes gift certificates and presents a link to order a gift certificate
  @author
  @creation-date
  @cvs-id gift-certificate-order.tcl,v 3.1.10.5 2000/08/17 21:23:07 seb Exp
} {

}



set system_name [ad_system_name]
set expiration_time [ec_decode [ad_parameter GiftCertificateMonths ecommerce] "12" "1 year" "24" "2 years" "[ad_parameter GiftCertificateMonths ecommerce] months"]
set minimum_amount [ec_pretty_price [ad_parameter MinGiftCertificateAmount ecommerce]]
set maximum_amount [ec_pretty_price [ad_parameter MaxGiftCertificateAmount ecommerce]]

if { [ad_ssl_available_p] } {
    set order_url "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]/ecommerce/gift-certificate-order-2"
} else {
    set order_url "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]/ecommerce/gift-certificate-order-2"
}


ad_return_template
