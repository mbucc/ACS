<%
# host-add-2.adp -- add a new host to the the glassroom_hosts table
#                   (this is an ADP as opposed to a .tcl file so that 
#                   it's consistent naming with host-add.adp)

set_the_usual_form_variables

# Expects hostname, ip_address, os_version, description,
#         model_and_serial, street_address, remote_console_instructions
#         service_phone_number, service_contract, facility_phone,
#         facility_contact, backup_strategy, rdbms_backup_strategy,
#         further_docs_url

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
	ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
	return
}




# check for bad input

set happy_p [glassroom_check_host_args $hostname $ip_address $further_docs_url]



if $happy_p {
    
    # Assuming we don't need to confirm entry.  Just add it to the
    # glassroom_hosts table
    
    set insert_sql "
    insert into glassroom_hosts
      (host_id, hostname, ip_address,
       os_version, description, model_and_serial,
       street_address, remote_console_instructions,
       service_phone_number, service_contract, facility_phone,
       facility_contact, backup_strategy, rdbms_backup_strategy,
       further_docs_url)
    values
      (glassroom_host_id_sequence.nextval, '$QQhostname', '$ip_address',
       '$QQos_version', '$QQdescription', '$QQmodel_and_serial',
       '$QQstreet_address', '$QQremote_console_instructions',
       '$QQservice_phone_number', '$QQservice_contract', '$QQfacility_phone',
       '$QQfacility_contact', '$QQbackup_strategy', '$QQrdbms_backup_strategy',
       '$QQfurther_docs_url')
    "
    
    set db [ns_db gethandle]
    ns_db dml $db "$insert_sql"
    ns_db releasehandle $db
    
    
    # and redirect back to index.tcl so folks can see the new host list
    
    ad_returnredirect "index.tcl"
}
%>

