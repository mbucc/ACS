# $Id: fulfill-3.tcl,v 3.0.4.1 2000/04/28 15:08:43 carsten Exp $
set_the_usual_form_variables
# shipment_id, order_id, shipment_date, expected_arrival_date, carrier, carrier_other,
# tracking_number, item_id_list

# We have to:
# 1. Add a row to ec_shipments.
# 2. Update item_state and shipment_id in ec_items.
# 3. Compute how much we need to charge the customer
#    (a) If the total amount is the same as the amount previously calculated
#        for the entire order, then update to_be_captured_p and to_be_captured_date
#        in ec_financial_transactions and try to mark the transaction*
#    (b) If the total amount is different and greater than 0:
#        I.  add a row to ec_financial_transactions with
#             to_be_captured_p and to_be_captured_date set
#        II. do a new authorization*
#        III.  mark transaction*

# * I was debating with myself whether it really makes sense to do the CyberCash
# transactions on this page since, by updating to_be_captured_* in
# ec_financial_transactions, a cron job can easily come around later and
# see what needs to be done.
# Pros: (1) instant feedback, if desired, if the transaction fails, which means the
#           shipment can possibly be aborted
#       (2) if it were done via a cron job, the cron job would need to query CyberCash
#           first to see if CyberCash had a record for the transaction before it could
#           try to auth/mark it (in case we had attempted the transaction before an got
#           an inconclusive result), whereas on this page there's no need to query first
#           (you know CyberCash doesn't have a record for it).  CyberCash charges 20
#           cents per transaction, although I don't actually know if a query is considered
#           a transaction.
# Cons: it slows things down for the person recording shipments

# I guess I'll just do the transactions on this page, for now, and if they prove too
# slow they can be taken out without terrible consequences (the cron job has to run
# anyway in case the results here are inconclusive).

# the customer service rep must be logged on
set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# doubleclick protection
if { [database_to_tcl_string $db "select count(*) from ec_shipments where shipment_id=$shipment_id"] > 0 } {
    ad_returnredirect fulfillment.tcl
    return
}

ns_db dml $db "begin transaction"

ns_db dml $db "insert into ec_shipments
(shipment_id, order_id, shipment_date, expected_arrival_date, carrier, tracking_number, last_modified, last_modifying_user, modified_ip_address)
values
($shipment_id, $order_id, to_date([ns_dbquotevalue $shipment_date],'YYYY-MM-DD HH24:MI:SS'), to_date([ns_dbquotevalue $expected_arrival_date],'YYYY-MM-DD HH24:MI:SS'), '$QQcarrier', '$QQtracking_number', sysdate, $customer_service_rep, '[DoubleApos [ns_conn peeraddr]]')
"

ns_db dml $db "update ec_items
set item_state='shipped', shipment_id=$shipment_id
where item_id in ([join $item_id_list ", "])"

# calculate the total shipment cost (price + shipping + tax - gift certificate) of the shipment
set shipment_cost [database_to_tcl_string $db "select ec_shipment_cost($shipment_id) from dual"]

# calculate the total order cost (price + shipping + tax - gift_certificate) so we'll
# know if we can use the original transaction
set order_cost [database_to_tcl_string $db "select ec_order_cost($order_id) from dual"]


# It is conceivable, albeit unlikely, that a partial shipment,
# return, and an addition of more items to the order by the site
# administrator can make the order_cost equal the shipment_cost
# even if it isn't the first shipment, which is fine.  But if
# this happens twice, this would have caused the system (which is
# trying to minimize financial transactions) to try to reuse an old
# transaction, which will fail, so I've added the 2nd half of the
# "if statement" below to make sure that transaction doesn't get reused:

if { $shipment_cost == $order_cost && [database_to_tcl_string $db "select count(*) from ec_financial_transactions where order_id=$order_id and to_be_captured_p='t'"] == 0} {
    set transaction_id [database_to_tcl_string $db "select max(transaction_id) from ec_financial_transactions where order_id=$order_id"]
    # 1999-08-11: added shipment_id to the update
    
    # 1999-08-29: put the update inside an if statement in case there is
    # no transaction to update
    if { ![empty_string_p $transaction_id] } {
	ns_db dml $db "update ec_financial_transactions set shipment_id=$shipment_id, to_be_captured_p='t', to_be_captured_date=sysdate where transaction_id=$transaction_id"
    }

    ns_db dml $db "end transaction"

    # try to mark the transaction
    # 1999-08-29: put the marking inside an if statement in case there is
    # no transaction to update
    if { ![empty_string_p $transaction_id] } {

	set cc_mark_result [ec_creditcard_marking $db $transaction_id]
	if { $cc_mark_result == "invalid_input" } {
	    ns_db dml $db "insert into ec_problems_log
	    (problem_id, problem_date, problem_details, order_id)
	    values
	    (ec_problem_id_sequence.nextval, sysdate, 'When trying to mark shipment $shipment_id (transaction $transaction_id) at [DoubleApos [ns_conn url]], the following result occurred: $cc_mark_result', $order_id)
	    "
	} elseif { $cc_mark_result == "success" } {
	    ns_db dml $db "update ec_financial_transactions set marked_date=sysdate where transaction_id=$transaction_id"
	}
    }
} else {
    if { $shipment_cost > 0 } {
	# 1. add a row to ec_financial_transactions with to_be_captured_p and to_be_captured_date set
	# 2. do a new authorization
	# 3. mark transaction

	# Note: 1 is the only one we want to do inside the transaction; if 2 & 3 fail, they will be
	# tried later with a cron job (they involve talking to CyberCash, so you never know what will
	# happen with them)

	set transaction_id [database_to_tcl_string $db "select ec_transaction_id_sequence.nextval from dual"]
	# 1999-08-11: added shipment_id to the insert

	ns_db dml $db "insert into ec_financial_transactions
	(transaction_id, order_id, shipment_id, transaction_amount, transaction_type, to_be_captured_p, inserted_date, to_be_captured_date)
	values
	($transaction_id, $order_id, $shipment_id, $shipment_cost, 'charge','t',sysdate,sysdate)
	"
	ns_db dml $db "end transaction"

	# CyberCash stuff
	# this attempts an auth and returns failed_authorization, authorized_plus_avs, authorized_minus_avs, no_recommendation, or invalid_input
	set cc_result [ec_creditcard_authorization $db $order_id $transaction_id]
	if { $cc_result == "failed_authorization" || $cc_result == "invalid_input" } {
	    ns_db dml $db "insert into ec_problems_log
	    (problem_id, problem_date, problem_details, order_id)
	    values
	    (ec_problem_id_sequence.nextval, sysdate, 'When trying to authorize shipment $shipment_id (transaction $transaction_id) at [DoubleApos [ns_conn url]], the following result occurred: $cc_result', $order_id)
	    "
	    
	    if { [ad_parameter DisplayTransactionMessagesDuringFulfillmentP ecommerce] } {
		ad_return_warning "Credit Card Failure" "Warning: the credit card authorization for this shipment (shipment_id $shipment_id) of order_id $order_id failed.  You may wish to abort the shipment (if possible) until this is issue is resolved.  A note has been made in the problems log.<p><a href=\"fulfillment.tcl\">Continue with order fulfillment.</a>"
		return
	    }
	    if { $cc_result == "failed_p" } {
		ns_db dml $db "update ec_financial_transactions set failed_p='t' where transaction_id=$transaction_id"
	    }
	} elseif { $cc_result == "authorized_plus_avs" || $cc_result == "authorized_minus_avs" } {
	    # put authorized_date into ec_financial_transacions
	    ns_db dml $db "update ec_financial_transactions set authorized_date=sysdate where transaction_id=$transaction_id"
	    # try to mark the transaction
	    set cc_mark_result [ec_creditcard_marking $db $transaction_id]
	    ns_log Notice "fulfill-3.tcl: cc_mark_result is $cc_mark_result"
	    if { $cc_mark_result == "invalid_input" } {
		ns_db dml $db "insert into ec_problems_log
		(problem_id, problem_date, problem_details, order_id)
		values
		(ec_problem_id_sequence.nextval, sysdate, 'When trying to mark shipment $shipment_id (transaction $transaction_id) at [DoubleApos [ns_conn url]], the following result occurred: $cc_mark_result', $order_id)
		"
	    } elseif { $cc_mark_result == "success" } {
		ns_db dml $db "update ec_financial_transactions set marked_date=sysdate where transaction_id=$transaction_id"
	    }
	}
    } else {
	ns_db dml $db "end transaction"
    }
}

# send the "Order Shipped" email
ec_email_order_shipped $shipment_id

ad_returnredirect "fulfillment.tcl"
