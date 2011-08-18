# $Id: host-delete.tcl,v 3.0.4.1 2000/04/28 15:10:43 carsten Exp $
# host-delete.tcl -- confirm the removal of a host from glassroom_hosts
#


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


# snarf the host name

set db [ns_db gethandle]

set select_sql "
select hostname
  from glassroom_hosts
 where host_id=$host_id"

set hostname [database_to_tcl_string_or_null $db $select_sql]

ns_db releasehandle $db


# emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete \"$hostname\""]

<h2>Delete \"$hostname\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list host-view.tcl?[export_url_vars host_id] "View Host"] "Delete Host"]
<hr>

Are you sure you want to delete this host?

<ul>
   <li> <a href=\"host-delete-2.tcl?[export_url_vars host_id]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"host-view.tcl?[export_url_vars host_id]\">no, let me look at the host info again</a>
</ul>

[glassroom_footer]
"





