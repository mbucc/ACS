# $Id: contact-edit-2.tcl,v 3.0.6.1 2000/04/28 15:09:36 carsten Exp $
set_the_usual_form_variables

# user_id and everything in user_contract

set db [ns_db gethandle]


set num_rows [database_to_tcl_string $db "select count(user_id)
from users_contact where user_id = $user_id"]

ns_set delkey [ns_getform] submit
 

if {$num_rows == 0} {
    ns_db dml $db [util_prepare_insert $db users_contact user_id $user_id [ns_getform]]
} else {
    ns_db dml $db [util_prepare_update $db users_contact user_id $user_id [ns_getform]]
}
 

ad_returnredirect "one.tcl?[export_url_vars user_id]"