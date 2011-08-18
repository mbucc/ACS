# $Id: service-delete-2.tcl,v 3.0.4.1 2000/04/28 15:10:54 carsten Exp $
# service-delete-2.tcl -- remove a service from glassroom_services
#

set_the_usual_form_variables

# Expects service_name

if { [ad_read_only_p] } {
    ad_return_read_only_maintenance_message
    return
}


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
	return
}



# emit the page contents

ReturnHeaders

ns_write "[ad_header "Service \"$service_name\" Deleted"]

<h2>Service \"$service_name\" Deleted</h2>
<hr>
"

set delete_sql "delete from glassroom_services where service_name='$QQservice_name'"

#!!! what to do if delete fails...

set db [ns_db gethandle]
ns_db dml $db $delete_sql

ns_db releasehandle $db


ns_write "
Deletion of $service_name confirmed.

<p>


<a href=index.tcl>Return to the Glass Room</a>

[glassroom_footer]
"