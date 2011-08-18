<%
# procedure-add.adp -- add a new procedure

set_form_variables 0

# Expects either nothing, or all the requisite form data when doing
#         a user search
#
# if search_token is set, that means that we've gotten to this page
# from a user search. expected token is "responsible_user"



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


if [info exists search_token] {
    if { $search_token == "responsible_user" } {
	set responsible_user $user_id_from_search
    }
}





# emit the page contents

ns_puts "
[ad_header "Add a new Procedure"]
<h2>Add a new Procedure</h2>
in [ad_context_bar [list index.tcl Glassroom] "Add Procedure"]
<hr>
"


set db [ns_db gethandle]

# include the shared HTML form

ns_adp_include "procedure-form.adp" "Add Procedure" "procedure-add-2.adp"

ns_db releasehandle $db


ns_puts "[glassroom_footer]"

%>


