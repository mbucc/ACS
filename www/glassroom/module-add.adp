<%
# module-add.adp -- add a new software module.
#


set_form_variables 0

# expects either nothing, or all of the requisite form data
#
# if search_token is set, that means that we've gotten to this page
# from a user search. expected tokens are "who_installed" and "who_owns"


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
    if { $search_token == "who_installed" } {
	set who_installed_it $user_id_from_search
    } elseif { $search_token == "who_owns" } {
	set who_owns_it $user_id_from_search
    }
}


# emit the page contents

ns_puts "
[ad_header "Add a new Software Module"]
<h2>Add a new Software Module</h2>
in [ad_context_bar [list index.tcl Glassroom] "Add Software Module"]
<hr>
"

# generate the module_id

set db [ns_db gethandle]

if ![info exists module_id] {
    set module_id [database_to_tcl_string $db "select glassroom_module_id_sequence.nextval from dual"]
}

# include the shared HTML form

ns_adp_include "module-form.adp" "Add Module" "module-add-2.adp"

ns_db releasehandle $db


ns_puts "[glassroom_footer]"

%>

