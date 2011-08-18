<%
# service-edit.adp -- edit a service in the glassroom_services table.  This file is an
#                  ADP so that we can ns_adp_include the service entry/editing
#                  form

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


# snarf the service information

set db [ns_db gethandle]

ns_log notice "Fnord: $QQservice_name"

set select_sql "
select web_service_host, rdbms_host, dns_primary_host, dns_secondary_host, disaster_host
  from glassroom_services
 where service_name = '$QQservice_name'"

set selection [ns_db 1row $db $select_sql]
set_variables_after_query



# emit the page contents

ns_puts "[ad_header "Edit Service \"$service_name\""]"

ns_puts "<h2>Edit Service \"$service_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list service-view.tcl?[export_url_vars service_name] "View Service"] "Edit Service"]
<hr>
"


# include the shared HTML form

ns_adp_include "service-form.adp" "Update Service" "service-edit-2.adp"

ns_db releasehandle $db


ns_puts "[glassroom_footer]"

%>

