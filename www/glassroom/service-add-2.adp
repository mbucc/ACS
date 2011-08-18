<%
# host-add-2.adp -- add a new host to the the glassroom_hosts table
#                   (this is an ADP as opposed to a .tcl file so that 
#                   it's consistent naming with host-add.adp)

set_the_usual_form_variables

# Expects service_name, web_service_host, rdbms_host, dns_primary_host, dns_secondary_host, disaster_host


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

set happy_p [glassroom_check_service_args $service_name $web_service_host $rdbms_host $dns_primary_host $dns_secondary_host $disaster_host]



if $happy_p {
    
    # Assuming we don't need to confirm entry.  Just add it to the
    # glassroom_services table

    if { [empty_string_p $web_service_host] } {
	set web_service_host "NULL"
    }
    if { [empty_string_p $rdbms_host] } {
	set rdbms_host "NULL"
    }
    if { [empty_string_p $dns_primary_host] } {
	set dns_primary_host "NULL"
    }
    if { [empty_string_p $dns_secondary_host] } {
	set dns_secondary_host "NULL"
    }
    if { [empty_string_p $disaster_host] } {
	set disaster_host "NULL"
    }
    
    set insert_sql "
    insert into glassroom_services
      (service_name, web_service_host, rdbms_host, dns_primary_host, dns_secondary_host, disaster_host)
    values
      ('$QQservice_name', $web_service_host, $rdbms_host, $dns_primary_host, $dns_secondary_host, $disaster_host)
    "
    
    set db [ns_db gethandle]
    ns_db dml $db "$insert_sql"
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new host list
    
    ad_returnredirect "index.tcl"
}
%>

