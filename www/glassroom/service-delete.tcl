# $Id: service-delete.tcl,v 3.0.4.1 2000/04/28 15:10:54 carsten Exp $
# service-delete.tcl -- confirm the removal of a service from glassroom_services
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


# snarf the service name

set db [ns_db gethandle]

set select_sql "
select service_name
  from glassroom_services
 where service_name='$QQservice_name'"

set service_name [database_to_tcl_string_or_null $db $select_sql]

ns_db releasehandle $db


# emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete \"$service_name\""]

<h2>Delete \"$service_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list service-view.tcl?[export_url_vars service_name] "View Service"] "Delete Service"]
<hr>

Are you sure you want to delete this service?

<ul>
   <li> <a href=\"service-delete-2.tcl?[export_url_vars service_name]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"service-view.tcl?[export_url_vars service_name]\">no, let me look at the service info again</a>
</ul>

[glassroom_footer]
"





