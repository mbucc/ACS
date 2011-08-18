<%
# logbook-add.tcl -- add a new logbook entry
#                    This file is an ADP so that we can ns_adp_include the 
#                    logbook entry entry/editing form

set_form_variables 0

# expects nothing, or perhaps the procedure name

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

ns_puts "[ad_header "Add a New Logbook Entry"]"

ns_puts "<h2>Add a New Logbook Entry</h2>
in [ad_context_bar [list index.tcl Glassroom] "Add Logbook Entry"]
<hr>
"


# include the shared HTML form

set db [ns_db gethandle]

if {![info exists notes]} {
	set notes ""
}

ns_adp_include "logbook-form.adp" "Add Logbook Entry" "logbook-add-2.adp"

ns_db releasehandle $db


ns_puts "[glassroom_footer]"

%>

