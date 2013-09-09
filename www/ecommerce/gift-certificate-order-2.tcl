#  www/ecommerce/gift-certificate-order-2.tcl
ad_page_contract {
 asks for gift certificate info like message, amount, recipient_email
  @author
  @creation-date
  @cvs-id gift-certificate-order-2.tcl,v 3.2.6.5 2000/08/18 21:46:33 stevenp Exp
} {
}


ec_redirect_to_https_if_possible_and_necessary

# user must be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ad_conn url]"

    ad_returnredirect "/register?[export_url_vars return_url]"
    return
}

set currency [ad_parameter Currency ecommerce]
set minimum_amount [ec_pretty_price [ad_parameter MinGiftCertificateAmount ecommerce]]
set maximum_amount [ec_pretty_price [ad_parameter MaxGiftCertificateAmount ecommerce]]


ad_return_template