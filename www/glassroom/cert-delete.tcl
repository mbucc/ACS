# $Id: cert-delete.tcl,v 3.0.4.1 2000/04/28 15:10:40 carsten Exp $
# cert-delete.tcl -- confirm the removal of a certificate from 
#                    glassroom_certificates
#

set_form_variables

# Expects cert_id

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



# snarf the hostname for the certificate name

set db [ns_db gethandle]

set select_sql "
select hostname
  from glassroom_certificates
 where cert_id=$cert_id"

set hostname [database_to_tcl_string_or_null $db $select_sql]

ns_db releasehandle $db


# emit the page contents

ReturnHeaders

ns_write "[ad_header "Delete Certificate for \"$hostname\""]

<h2>Delete Certificate for \"$hostname\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list cert-view.tcl?[export_url_vars cert_id] "View Certificate"] "Delete Certificate"]
<hr>

Are you sure you want to delete this certificate?

<ul>
   <li> <a href=\"cert-delete-2.tcl?[export_url_vars cert_id]\">yes, I'm sure</a>
        <br><br>

   <li> <a href=\"cert-view.tcl?[export_url_vars cert_id]\">no, let me look at the cert info again</a>
</ul>

[glassroom_footer]
"

