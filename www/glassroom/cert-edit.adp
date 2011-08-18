<%
# cert-edit.adp -- edit a certificate in the glassroom_certificates table.  
#                  This file is an ADP so that we can ns_adp_include the 
#                  cert entry/editing form

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


# snarf the cert information

set db [ns_db gethandle]

set select_sql "
select hostname, issuer, encoded_email, expires
  from glassroom_certificates
 where cert_id=$cert_id"

set selection [ns_db 1row $db $select_sql]
set_variables_after_query

ns_db releasehandle $db




# emit the page contents

ns_puts "[ad_header "Edit Certificate for \"$hostname\""]"

ns_puts "<h2>Edit Certificate for \"$hostname\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list cert-view.tcl?[export_url_vars cert_id] "View Certificate"] "Edit Certificate"]
<hr>
"


# include the shared HTML form

ns_adp_include "cert-form.adp" "Update Certificate" "cert-edit-2.adp"



ns_puts "[glassroom_footer]"

%>

