<%
# release-add.adp -- add a new release to a software module

set_form_variables 0

# Expects either nothing, or all the requisite form data when doing
#         a user search
#
# if search_token is set, that means that we've gotten to this page
# from a user search. expected token is "manager"


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
    if { $search_token == "manager" } {
	set manager $user_id_from_search
    }
}


# emit the page contents

ns_puts "
[ad_header "Add a new Software Release"]
<h2>Add a new Software Release</h2>
in [ad_context_bar [list index.tcl Glassroom] "Add Software Release"]
<hr>
"

# generate the release_id

set db [ns_db gethandle]

if ![info exists release_id] {
    set release_id [database_to_tcl_string $db "select glassroom_release_id_sequence.nextval from dual"]
}

# include the shared HTML form

ns_adp_include "release-form.adp" "Add Release" "release-add-2.adp"

ns_db releasehandle $db


ns_puts "[glassroom_footer]"

%>


