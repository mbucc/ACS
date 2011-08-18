<%
# service-add.adp -- add a new service to the glassroom_services table
#                 This file is an ADP so that we can ns_adp_include the 
#                 service entry/editing form

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

ns_puts "[ad_header "Add a new Service"]"

ns_puts "<h2>Add a new Service</h2>
in [ad_context_bar [list index.tcl Glassroom] "Add Service"]
<hr>
"


# include the shared HTML form

set db [ns_db gethandle]
ns_adp_include "service-form.adp" "Add Service" "service-add-2.adp"
ns_db releasehandle $db


ns_puts "[glassroom_footer]"

%>

