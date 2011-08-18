# $Id: gift-certificate-claim-2.tcl,v 3.0.4.1 2000/04/28 15:10:00 carsten Exp $
set_the_usual_form_variables
# claim_check

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order and a user_session_id;
# this will make it more annoying for someone who just wants to
# come to this page and try random number after random number

set user_session_id [ec_get_user_session_id]

if { $user_session_id == 0 } {
    ad_returnredirect "index.tcl"
    return
}

set db [ns_db gethandle]

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]
if { [empty_string_p $order_id] } {
    ad_returnredirect "index.tcl"
    return
}

if { [empty_string_p $claim_check] } {
    ad_return_complaint 1 "<li>You forgot to enter a claim check."
    return
}

# see if there's a gift certificate with that claim check

set gift_certificate_id [database_to_tcl_string_or_null $db "select gift_certificate_id from ec_gift_certificates where claim_check='$QQclaim_check'"]

if { [empty_string_p $gift_certificate_id] } {
    
    ad_return_complaint 1 "The claim check you have entered is invalid.  Please re-check it.  The claim check is case sensitive; enter it exactly as shown on your gift certificate."

    ns_db dml $db "insert into ec_problems_log
    (problem_id, problem_date, problem_details)
    values
    (ec_problem_id_sequence.nextval, sysdate, '[DoubleApos "Incorrect gift certificate claim check entered at [ns_conn url].  Claim check entered: $claim_check by user ID: $user_id.  They may have just made a typo but if this happens repeatedly from the same IP address ([ns_conn peeraddr]) you may wish to look into this."]')
    "

    return
}

# there is a gift certificate with that claim check;
# now check whether it's already been claimed
# and, if so, whether it was claimed by this user

set selection [ns_db 1row $db "select user_id as gift_certificate_user_id, amount from ec_gift_certificates where gift_certificate_id=$gift_certificate_id"]
set_variables_after_query

if { [empty_string_p $gift_certificate_user_id ] } {
    # then no one has claimed it, so go ahead and assign it to them
    ns_db dml $db "update ec_gift_certificates set user_id=$user_id, claimed_date=sysdate where gift_certificate_id=$gift_certificate_id"

    ReturnHeaders
    ns_write "[ad_header "Gift Certificate Claimed"]
    [ec_header_image]<br clear=all>
    <blockquote>
    [ec_pretty_price $amount] has been added to your gift certificate account!
    <p>
    <a href=\"payment.tcl\">Continue with your order</a>
    </blockquote>
    [ec_footer $db]
    "
    return
} else {
    # it's already been claimed
    ReturnHeaders
    ns_write "[ad_header "Gift Certificate Already Claimed"]
    [ec_header_image]<br clear=all>
    <blockquote>
    Your gift certificate has already been claimed.  Either you hit submit twice on the form, or it
    was claimed previously.  Once you claim it, it goes into your gift
    certificate balance and you don't have to claim it again.
    <p>
    <a href=\"payment.tcl\">Continue with your order</a>
    </blockquote>
    [ec_footer $db]
    "

    # see if it was claimed by a different user and, if so, record the problem
    if { $user_id != $gift_certificate_user_id } {
	ns_db dml $db "insert into ec_problems_log
	(problem_id, problem_date, gift_certificate_id, problem_details)
	values
	(ec_problem_id_sequence.nextval, sysdate, $gift_certificate_id, '[DoubleApos "User ID $user_id tried to claim gift certificate $gift_certificate_id at [DoubleApos [ns_conn url]], but it had already been claimed by User ID $gift_certificate_id."])
	"
    }
    return
}

