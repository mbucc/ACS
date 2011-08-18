# $Id: host-view.tcl,v 3.0.4.1 2000/04/28 15:10:43 carsten Exp $
# host-view.tcl -- view a host's information, and also give them the option
#                  to edit or delete the information


set_form_variables

# Expects host_id


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

set selection [ns_db 0or1row $db $select_sql]

if { [empty_string_p $selection] } {
    # if it's not there, just redirect them to the index page
    # (if they hacked the URL, they get what they deserve, if the
    # the host has been deleted, they can see the list of valid hosts)
    ad_returnredirect index.tcl
    return
}

set_variables_after_query

ns_db releasehandle $db


# emit the page contents

ReturnHeaders

ns_write "[ad_header $hostname]

<h2>$hostname</h2>
in [ad_context_bar [list index.tcl Glassroom] "View Host"]
<hr>

<h3>The Host</h3>

<ul>
    <li> <b>Hostname:</b> $hostname
         <p>

    <li> <b>IP Address:</b> $ip_address
         <p>

    <li> <b>OS and Version:</b> $os_version
         <p>

    <li> <b>Physical Configuration:</b> $description
         <p>

    <li> <b>Model and Serial#</b> $model_and_serial
         <p>

    <li> <b>Address</b> $street_address
         <p>

    <li> <b>How to get to console port</b> $remote_console_instructions
         <p>

    <li> <b>Service number</b> $service_phone_number
         <p>

    <li> <b>Service contract:</b> $service_contract
         <p>

    <li> <b>Hosting phone:</b> $facility_phone
         <p>

    <li> <b>Hosting contact:</b> $facility_contact
         <p>

    <li> <b>Backup strategy:</b> $backup_strategy
         <p>

    <li> <b>RDBMS backup strategy:</b> $rdbms_backup_strategy
         <p>

    <li> <b>Further Documentation:</b> <a href=\"$further_docs_url\">$further_docs_url</a>
</ul>
"


ns_write "

<h3>Actions</h3>

<ul>
   <li> <a href=\"host-edit.adp?[export_url_vars host_id]\">Edit</a>
        <p>

   <li> <a href=\"host-delete.tcl?[export_url_vars host_id]\">Delete</a>

</ul>

[glassroom_footer]
"


