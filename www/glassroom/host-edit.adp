<%
# host-edit.adp -- edit a host in the glassroom_hosts table.  This file is an
#                  ADP so that we can ns_adp_include the host entry/editing
#                  form

set_form_variables

# Expects host_id

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


# snarf the host information

set db [ns_db gethandle]

set select_sql "
select hostname, ip_address, os_version, description, model_and_serial,
       street_address, remote_console_instructions, service_phone_number,
       service_contract, facility_phone, facility_contact, backup_strategy,
       rdbms_backup_strategy, further_docs_url
  from glassroom_hosts
 where host_id=$host_id"

set selection [ns_db 1row $db $select_sql]
set_variables_after_query

ns_db releasehandle $db




# emit the page contents

ns_puts "[ad_header "Edit Host \"$hostname\""]"

ns_puts "<h2>Edit Host \"$hostname\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list host-view.tcl?[export_url_vars host_id] "View Host"] "Edit Host"]
<hr>
"


# include the shared HTML form

ns_adp_include "host-form.adp" "Update Host" "host-edit-2.adp"



ns_puts "[glassroom_footer]"

%>

