<%
# cert-add.tcl -- add a new certificatex to the list of certs that the
#                 glass room handles This file is an ADP so that we can 
#                 ns_adp_include the cert entry/editing form

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


# emit the page contents

ns_puts "
[ad_header "Add a new Certificate"]
<h2>Add a new Certificate</h2>
in [ad_context_bar [list index.tcl Glassroom] "Add Certificate"]
<hr>
"


# include the shared HTML form

ns_adp_include "cert-form.adp" "Add Certificate" "cert-add-2.adp"



ns_puts "[glassroom_footer]"

%>

