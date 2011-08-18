# $Id: creditcard-add-3.tcl,v 3.0.4.1 2000/04/28 15:08:43 carsten Exp $
set_the_usual_form_variables
# order_id,
# creditcard_number, creditcard_type, creditcard_expire_1,
# creditcard_expire_2, billing_zip_code

set db [ns_db gethandle]
ns_db dml $db "begin transaction"

set user_id [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]

set creditcard_id [database_to_tcl_string $db "select ec_creditcard_id_sequence.nextval from dual"]

ns_db dml $db "insert into ec_creditcards
(creditcard_id, user_id, creditcard_number, creditcard_last_four, creditcard_type, creditcard_expire, billing_zip_code)
values
($creditcard_id, $user_id, '$creditcard_number', '[string range $creditcard_number [expr [string length $creditcard_number] -4] [expr [string length $creditcard_number] -1]]', '[DoubleApos $creditcard_type]','$creditcard_expire_1/$creditcard_expire_2','[DoubleApos $billing_zip_code]')
"

ns_db dml $db "update ec_orders set creditcard_id=$creditcard_id where order_id=$order_id"

ns_db dml $db "end transaction"

ad_returnredirect "one.tcl?[export_url_vars order_id]"
