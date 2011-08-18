# $Id: service-view.tcl,v 3.0.4.1 2000/04/28 15:10:54 carsten Exp $
# service-view.tcl -- view a service's information, and also give them the option
#                     to edit or delete the information


set_the_usual_form_variables

# Expects service_name


# check for user

set user_id [ad_verify_and_get_user_id]

if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


# get the service data


set db [ns_db gethandle]

set select_sql "
select web_service_host, rdbms_host, dns_primary_host, dns_secondary_host, disaster_host
  from glassroom_services
 where service_name = '$QQservice_name'"

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the host has been deleted, they can see the list of valid hosts)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query


if { ![empty_string_p $web_service_host] } {
    set web_service_host [database_to_tcl_string_or_null $db "select hostname from glassroom_hosts where host_id = $web_service_host"]
} else {
    set web_service_host "None"
}
if { ![empty_string_p $rdbms_host] } {
    set rdbms_host [database_to_tcl_string_or_null $db "select hostname from glassroom_hosts where host_id = $rdbms_host"]
} else {
    set rdbms_host "None"
}
if { ![empty_string_p $dns_primary_host] } {
    set dns_primary_host [database_to_tcl_string_or_null $db "select hostname from glassroom_hosts where host_id = $dns_primary_host"]
} else {
    set dns_primary_host "None"
}
if { ![empty_string_p $dns_secondary_host] } {
    set dns_secondary_host [database_to_tcl_string_or_null $db "select hostname from glassroom_hosts where host_id = $dns_secondary_host"]
} else {
    set dns_secondary_host "None"
}
if { ![empty_string_p $disaster_host] } {
    set disaster_host [database_to_tcl_string_or_null $db "select hostname from glassroom_hosts where host_id = $disaster_host"]
} else {
    set disaster_host "None"
}


# emit the page contents


ReturnHeaders

ns_write "[ad_header $service_name]

<h2>$service_name</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Service"]
<hr>

<h3>The Service</h3>

<ul>
    <li> <b>Service Name:</b> $service_name
         <p>

    <li> <b> Web Service Host:</b> $web_service_host
         <p>

    <li> <b> RDBMS Host:</b> $rdbms_host
         <p>

    <li> <b> DNS Primary Host:</b> $dns_primary_host
         <p>

    <li> <b> DNS Secondary Host:</b> $dns_secondary_host
         <p>

    <li> <b> Disaster Host:</b> $disaster_host
         <p>

</ul>
"



ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"service-edit.adp?[export_url_vars service_name]\">Edit</a>
        <p>

   <li> <a href=\"service-delete.tcl?[export_url_vars service_name]\">Delete</a>

</ul>

[glassroom_footer]
"


