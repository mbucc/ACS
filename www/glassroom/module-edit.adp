<%
# module-edit.adp -- edit a software module in the glassroom_modules table.
#                    This file is an ADP so that we can ns_adp_include the 
#                    entry/editing form


set_form_variables

# Expects module_id, or all of the requisite form data
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


set db [ns_db gethandle]

    
if [info exists search_token] {
    # means we're on a return-trip from user searching
    if { $search_token == "who_installed" } {
	set who_installed_it $user_id_from_search
    } elseif { $search_token == "who_owns" } {
	set who_owns_it $user_id_from_search
    }
} else {
    
    # snarf the module information
    
    set select_sql "
    select module_name, source, current_version, who_installed_it, who_owns_it
      from glassroom_modules
     where module_id=$module_id"
    
    set selection [ns_db 1row $db $select_sql]

    set_variables_after_query
}



# emit the page contents

ns_puts "[ad_header "Edit Module \"$module_name $current_version\""]"

ns_puts "<h2>Edit Module \"$module_name $current_version\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list module-view.tcl?[export_url_vars module_id] "View Module"] "Edit Module"]
<hr>
"


# include the shared HTML form

ns_adp_include "module-form.adp" "Update Module" "module-edit-2.adp"



ns_puts "[glassroom_footer]"

%>

