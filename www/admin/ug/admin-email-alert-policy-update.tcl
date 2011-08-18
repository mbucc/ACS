# $Id: admin-email-alert-policy-update.tcl,v 3.0.4.1 2000/04/28 15:09:25 carsten Exp $
# Toggle the flag which sends email to admin when a user applies for
# group membership.
#
# Form variables: 
# group_id       the id of the group


set_form_variables

set db [ns_db gethandle]

ns_db dml $db "update user_groups set email_alert_p = logical_negation(email_alert_p) where group_id = $group_id"

ad_returnredirect "group.tcl?[export_url_vars group_id]"
