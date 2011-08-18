# $Id: email-send-2.tcl,v 3.0.4.1 2000/04/28 15:08:37 carsten Exp $
set_the_usual_form_variables
# action_id, issue_id, customer_service_rep,
# email_to_use, cc_to, bcc_to, subject, message,
# user_identification_id

# no confirm page because they were just sent through the spell
# checker (that's enough submits to push)

# check for double-click
set db [ns_db gethandle]

if { [database_to_tcl_string $db "select count(*) from ec_customer_service_actions where action_id=$action_id"] > 0 } {
    ad_returnredirect "issue.tcl?[export_url_vars issue_id]"
    return
}

# 1. create interaction
# 2. create action
# 3. send email

set email_from [ad_parameter CustomerServiceEmailAddress ecommerce]

set action_details "From: $email_from
To: $email_to_use
"
if { ![empty_string_p $cc_to] } {
    append action_details "Cc: $cc_to
    "
}
if { ![empty_string_p $bcc_to] } {
    append action_details "Bcc: $bcc_to
    "
}

append action_details "Subject: $subject

$message
"

ns_db dml $db "begin transaction"

set interaction_id [database_to_tcl_string $db "select ec_interaction_id_sequence.nextval from dual"]

ns_db dml $db "insert into ec_customer_serv_interactions
(interaction_id, customer_service_rep, user_identification_id, interaction_date, interaction_originator, interaction_type)
values
($interaction_id, $customer_service_rep, $user_identification_id, sysdate, 'rep', 'email')
"

ns_db dml $db "insert into ec_customer_service_actions
(action_id, issue_id, interaction_id, action_details)
values
($action_id, $issue_id, $interaction_id, '[DoubleApos $action_details]')
"

ns_db dml $db "end transaction"

set extra_headers [ns_set new]
if { [info exists cc_to] && $cc_to != "" } {
    ns_set put $extra_headers "Cc" "$cc_to"
    ec_sendmail_from_service $email_to_use [ad_parameter CustomerServiceEmailAddress ecommerce] $subject $message $extra_headers $bcc_to
} else {
    ec_sendmail_from_service $email_to_use [ad_parameter CustomerServiceEmailAddress ecommerce] $subject $message "" $bcc_to
}

ad_returnredirect "issue.tcl?issue_id=$issue_id"