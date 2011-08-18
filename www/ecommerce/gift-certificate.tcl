# $Id: gift-certificate.tcl,v 3.0.4.1 2000/04/28 15:10:01 carsten Exp $
set_the_usual_form_variables
# gift_certificate_id
# possibly usca_p

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# user session tracking
set user_session_id [ec_get_user_session_id]

ec_create_new_session_if_necessary [export_url_vars gift_certificate_id]

ec_log_user_as_user_id_for_this_session

set selection [ns_db 0or1row $db "select purchased_by, amount, recipient_email, certificate_to, certificate_from, certificate_message from ec_gift_certificates where gift_certificate_id=$gift_certificate_id"]

if { [empty_string_p $selection] } {
    set gift_certificate_summary "Invalid Gift Certificate ID"
} else {
    set_variables_after_query

    if { $user_id != $purchased_by } {
	set gift_certificate_summary "Invalid Gift Certificate ID"
    } else {

	set gift_certificate_summary "
	Gift Certificate #:
	$gift_certificate_id
	<p>
	Status:
	"
	
	set status [ec_gift_certificate_status $db $gift_certificate_id]
	
	if { $status == "Void" || $status == "Failed Authorization" } {
	    append gift_certificate_summary "<font color=red>$status</font>"
	} else {
	    append gift_certificate_summary "$status"
	}
	
	append gift_certificate_summary "<p>
	Recipient:
	$recipient_email
	<p>
	To: $certificate_to<br>
	Amount:	[ec_pretty_price $amount]<br>
	From: $certificate_from<br>
	Message: $certificate_message
	"
    }
}

ad_return_template