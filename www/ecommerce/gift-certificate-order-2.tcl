# $Id: gift-certificate-order-2.tcl,v 3.1.2.1 2000/04/28 15:10:00 carsten Exp $
# asks for gift certificate info like message, amount, recipient_email

ec_redirect_to_https_if_possible_and_necessary

# user must be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set currency [ad_parameter Currency ecommerce]
set minimum_amount [ec_pretty_price [ad_parameter MinGiftCertificateAmount ecommerce]]
set maximum_amount [ec_pretty_price [ad_parameter MaxGiftCertificateAmount ecommerce]]

set db [ns_db gethandle]
ad_return_template