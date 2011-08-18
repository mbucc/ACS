# $Id: items-void-2.tcl,v 3.0.4.1 2000/04/28 15:08:45 carsten Exp $
set_the_usual_form_variables
# order_id, product_id
# and possibly a series of item_ids from checkboxes (if there's more than one)

# we need them to be logged in
set customer_service_rep [ad_verify_and_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}


# See if there's a gift certificate amount applied to this order that's being
# tied up by unshipped items, in which case we may need to reinstate some or
# all of it.
# The equations are:
# (tied up g.c. amount) = (g.c. bal applied to order) - (amount paid for shipped items)
#                         + (amount refunded for shipped items)
# (amount to be reinstated for to-be-voided items) = (tied up g.c. amount)
#                                                     - (total cost of unshipped items)
#                                                     + (cost of to-be-voided items)
#
# So, (amount to be reinstated) = (g.c. bal applied to order) - (amount paid for shipped items)
# + (amount refunded for shipped items) - (total cost of unshipped items) + cost of to-be-voided items)
# = (g.c. bal applied to order) - (total amount for all nonvoid items in the order, incl the ones that are about to be voided)
#   + (total amount refunded on nonvoid items)
#   + (cost of to-be-voided items)
# = (g.c. bal applied to order) - (total amount for all nonvoid items in the order after these are voided)
#   + total amount refunded on nonvoid items
# This equation is now officially simple to solve.  G.c. balance should be calculated first, then things
# should be voided, then final calculation should be made and g.c.'s should be reinstated.

set db [ns_db gethandle]

ns_db dml $db "begin transaction"

set gift_certificate_amount [database_to_tcl_string $db "select ec_order_gift_cert_amount($order_id) from dual"]

# see if there's more than one item in this order with that order_id & product_id

set n_items [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id and product_id=$product_id"]

if { $n_items > 1 } {
    # make sure they checked at least one checkbox
    set form [ns_conn form]
    set item_id_list [util_GetCheckboxValues $form item_id]
    if { [llength $item_id_list] == 1 && [lindex 0 $item_id_list] == 0 } {
	ad_return_complaint 1 "<li>You didn't check off any items."
	return
    }
    ns_db dml $db "update ec_items set item_state='void', voided_date=sysdate, voided_by=$customer_service_rep where item_id in ([join $item_id_list ", "])"
} else {
    ns_db dml $db "update ec_items set item_state='void', voided_date=sysdate, voided_by=$customer_service_rep where order_id=$order_id and product_id=$product_id"
}

set amount_charged_minus_refunded_for_nonvoid_items [database_to_tcl_string $db "select nvl(sum(nvl(price_charged,0)) + sum(nvl(shipping_charged,0)) + sum(nvl(price_tax_charged,0)) + sum(nvl(shipping_tax_charged,0)) - sum(nvl(price_refunded,0)) - sum(nvl(shipping_refunded,0)) + sum(nvl(price_tax_refunded,0)) - sum(nvl(shipping_tax_refunded,0)),0) from ec_items where item_state <> 'void' and order_id=$order_id"]

set certificate_amount_to_reinstate [expr $gift_certificate_amount - $amount_charged_minus_refunded_for_nonvoid_items]

if { $certificate_amount_to_reinstate > 0 } {

    set certs_to_reinstate_list [list]

    set certs_to_reinstate_list [database_to_tcl_list $db "select u.gift_certificate_id
    from ec_gift_certificate_usage u, ec_gift_certificates c
    where u.gift_certificate_id = c.gift_certificate_id
    and u.order_id = $order_id
    order by expires desc"]

    # the amount used on that order
    set certificate_amount_used [database_to_tcl_string $db "select ec_order_gift_cert_amount($order_id) from dual"]

    if { $certificate_amount_used < $certificate_amount_to_reinstate } {
	ns_db dml $db "insert into ec_problems_log
	(problem_id, problem_date, problem_details, order_id)
	values
	(ec_problem_id_sequence.nextval, sysdate, 'We were unable to reinstate the customer''s gift certificate balance because the amount to be reinstated was larger than the original amount used.  This shouldn''t have happened unless there was a programming error or unless the database was incorrectly updated manually.  The voiding of this order has been aborted.', $order_id)
	"
	ad_return_error "Gift Certificate Error" "We were unable to reinstate the customer's gift certificate balance because the amount to be reinstated was larger than the original amount used.  This shouldn't have happened unless there was a programming error or unless the database was incorrectly updated manually.<p>The voiding of this order has been aborted.  This has been logged in the problems log."
	return
    } else {
	# go through and reinstate certificates in order; it's not so bad
	# to loop through all of them because I don't expect there to be
	# many

	set amount_to_reinstate $certificate_amount_to_reinstate
	foreach cert $certs_to_reinstate_list {
	    if { $amount_to_reinstate > 0 } {
		
		# any amount up to the original amount used on this order can be reinstated
		set reinstatable_amount [database_to_tcl_string $db "select ec_one_gift_cert_on_one_order($cert,$order_id) from dual"]

		if { $reinstatable_amount > 0 } {
		    set iteration_reinstate_amount [ec_min $reinstatable_amount $amount_to_reinstate]
		    
		    ns_db dml $db "insert into ec_gift_certificate_usage
		    (gift_certificate_id, order_id, amount_reinstated, reinstated_date)
		    values
		    ($cert, $order_id, $iteration_reinstate_amount, sysdate)
		    "
		    
		    set amount_to_reinstate [expr $amount_to_reinstate - $iteration_reinstate_amount]
		}
	    }
	}
    }
}

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars order_id]"
