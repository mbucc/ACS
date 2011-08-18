# $Id: project-payment-ae-2.tcl,v 3.2.2.2 2000/04/28 15:11:09 carsten Exp $
# File: /www/intranet/payments/project-payment-ae-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# Purpose: records payments
#

set_the_usual_form_variables

# group_id, payment_id, start_block, fee, fee_types
# due_date, received_date, note

set db [ns_db gethandle]

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set required_vars [list [list start_block "Missing starting date"] [list fee_type "Missing fee type"]]


regsub "," $fee "" fee


ns_db dml $db "update im_project_payments set 
    start_block = '$start_block',
    fee = '$fee',
    fee_type = '$QQfee_type',
    last_modified = sysdate,
    last_modifying_user = $user_id,
    modified_ip_address = '[ns_conn peeraddr]',
    note = '$QQnote'
    where payment_id = $payment_id"

if {[ns_ora resultrows $db] == 0} {
    ns_db dml $db "insert into im_project_payments 
    (payment_id, group_id, start_block, fee, fee_type,  
    note, last_modified, last_modifying_user, modified_ip_address)
    values ($payment_id, $group_id, '$start_block', $fee, 
    '$QQfee_type', '$QQnote', sysdate,$user_id, '[ns_conn peeraddr]')"
}

ad_returnredirect "index.tcl?[export_url_vars group_id]"

ns_conn close

# email the people in the intranet billing group

set project_name [database_to_tcl_string $db \
	"select group_name from user_groups where group_id = $group_id"]

set editing_user [database_to_tcl_string $db \
	"select first_names || ' ' || last_name from users where user_id = $user_id"]

set selection [ns_db select $db "select email, first_names, last_name 
from users, administration_info
where administration_info.module = 'intranet'
and administration_info.submodule = 'billing'
and ad_group_member_p ( users.user_id, administration_info.group_id ) = 't'"]

set message "

A payment for $project_name has been changed by $editing_user.

Work starting: $start_block
Type:  $fee_type
Note: $note

To view online: [im_url]/payments/index.tcl?[export_url_vars group_id]

"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_log Notice "Sending email to $email"
    # ns_sendmail $email "[ad_parameter SpamRobotFromAddress spam]" "Change to $project_name payment plan." "$message"
}
