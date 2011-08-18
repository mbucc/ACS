<%
# service-edit-2.adp -- commit changes made to a service in the glassroom_services table
#                    (this is an ADP instead of a Tcl file to be consistent
#                    with service-edi.adp)

set_the_usual_form_variables

# Expects service_name, old_service_name, web_service_host, rdbms_host, dns_primary_host, dns_secondary_host, disaster_host



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

    set update_sql "
    update glassroom_services
    set 
        service_name='$QQservice_name',
        web_service_host=$web_service_host,
        rdbms_host=$rdbms_host,
        dns_primary_host=$dns_primary_host,
        dns_secondary_host=$dns_secondary_host,
        disaster_host=$disaster_host
    where service_name = '$QQold_service_name'"

    set db [ns_db gethandle]
    ns_db dml $db $update_sql
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new service list
    
    ad_returnredirect "service-view.tcl?[export_url_vars service_name]"
}
%>
