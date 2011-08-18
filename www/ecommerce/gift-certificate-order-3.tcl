# $Id: gift-certificate-order-3.tcl,v 3.1.2.1 2000/04/28 15:10:01 carsten Exp $
# asks for payment info

set_the_usual_form_variables
# certificate_to, certificate_from, certificate_message, amount, recipient_email

ec_redirect_to_https_if_possible_and_necessary

# user must be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# error checking

set exception_count 0
set exception_text ""

if { [string length $certificate_message] > 200 } {
    incr exception_count
    append exception_text "<li>The message you entered was too long.  It needs to contain fewer than 200 characters (the current length is [string length $certificate_message] characters)."
} 
if { [string length $certificate_to] > 100 } {
    incr exception_count
    append exception_text "<li>What you entered in the \"To\" field is too long.  It needs to contain fewer than 100 characters (the current length is [string length $certificate_to] characters)."
} 
if { [string length $certificate_from] > 100 } {
    incr exception_count
    append exception_text "<li>What you entered in the \"From\" field is too long.  It needs to contain fewer than 100 characters (the current length is [string length $certificate_from] characters)."
} 
if { [string length $recipient_email] > 100 } {
    incr exception_count
    append exception_text "<li>The recipient email address you entered is too long.  It needs to contain fewer than 100 characters (the current length is [string length $recipient_email] characters)."
}


if { [empty_string_p $amount] } {
    incr exception_count
    append exception_text "<li>You forgot to enter the amount of the gift certificate."
} elseif { [regexp {[^0-9]} $amount] } {
    incr exception_count
    append exception_text "<li>The amount needs to be a number with no special characters."
} elseif { $amount < [ad_parameter MinGiftCertificateAmount ecommerce] } {
    incr exception_count
    append exception_text "<li>The amount needs to be at least [ec_pretty_price [ad_parameter MinGiftCertificateAmount ecommerce]]"
} elseif { $amount > [ad_parameter MaxGiftCertificateAmount ecommerce] } {
    incr exception_count
    append exception_text "<li>The amount cannot be higher than [ec_pretty_price [ad_parameter MaxGiftCertificateAmount ecommerce]]"
}

if { [empty_string_p $recipient_email] } {
    incr exception_count
    append exception_text "<li>You forgot to specify the recipient's email address (we need it so we can send them their gift certificate!)"
} elseif {![philg_email_valid_p $recipient_email]} {
    incr exception_count
    append exception_text "<li>The recipient's email address that you typed doesn't look right to us.  Examples of valid email addresses are 
<ul>
<li>Alice1234@aol.com
<li>joe_smith@hp.com
<li>pierre@inria.fr
</ul>
"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set db [ns_db gethandle]

set ec_creditcard_widget [ec_creditcard_widget]
set ec_expires_widget "[ec_creditcard_expire_1_widget] [ec_creditcard_expire_2_widget]"
set zip_code [database_to_tcl_string_or_null $db "select zip_code from ec_addresses where address_id=(select max(address_id) from ec_addresses where user_id=$user_id)"]
set hidden_form_variables [export_form_vars certificate_to certificate_from certificate_message amount recipient_email]

ad_return_template