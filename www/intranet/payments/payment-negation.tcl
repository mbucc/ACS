# $Id: payment-negation.tcl,v 3.0.4.2 2000/04/28 15:11:09 carsten Exp $
# File: /www/intranet/payments/payment-negation.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: toggles the paid_p column for a specified payment
#

set_the_usual_form_variables

# return_url, payment_id

set db [ns_db gethandle]

ns_db dml $db "update im_project_payments set paid_p  = logical_negation(paid_p), received_date = sysdate where payment_id= $payment_id"

ad_returnredirect $return_url
