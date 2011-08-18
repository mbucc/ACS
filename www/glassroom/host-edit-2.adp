<%
# host-edit-2.adp -- commit changes made to a host in the glassroom_hosts table
#                    (this is an ADP instead of a Tcl file to be consistent
#                    with host-edi.adp)

set_the_usual_form_variables

# Expects host_id, hostname, ip_address, os_version, description,
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

    set update_sql "
    update glassroom_hosts
    set 
        hostname='$QQhostname',
        ip_address='$QQip_address',
        os_version='$QQos_version',
        description='$QQdescription',
        model_and_serial='$QQmodel_and_serial',
        street_address='$QQstreet_address',
        remote_console_instructions='$QQremote_console_instructions',
        service_phone_number='$QQservice_phone_number',
        service_contract='$QQservice_contract',
        facility_phone='$QQfacility_phone',
        facility_contact='$QQfacility_contact',
        backup_strategy='$QQbackup_strategy',
        rdbms_backup_strategy='$QQrdbms_backup_strategy',
        further_docs_url='$QQfurther_docs_url'
    where host_id=$host_id"

    set db [ns_db gethandle]
    ns_db dml $db $update_sql
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new host list
    
    ad_returnredirect "host-view.tcl?[export_url_vars host_id]"
}
%>
