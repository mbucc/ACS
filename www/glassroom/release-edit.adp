<%
# release-edit.adp -- edit a software release in the glassroom_releases table.
#                    This file is an ADP so that we can ns_adp_include the 
#                    entry/editing form


set_form_variables

# Expects release_id, or all of the requisite form data
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

set db [ns_db gethandle]
    
if [info exists search_token] {
    # means we're on a return-trip from user searching
    if { $search_token == "manager" } {
	set manager $user_id_from_search
    }

} else {
    
    # snarf the module information
    
    set select_sql "
    select release_name, manager, release_date, anticipated_release_date, module_id
      from glassroom_releases
     where release_id=$release_id"
    
    set selection [ns_db 1row $db $select_sql]

    if { [empty_string_p $selection] } {
	
	# if it's not there, just redirect them to the index page
	# (if they hacked the URL, they get what they deserve, if the
	# the module has been deleted, they can see the list of valid modules)
	ad_returnredirect index.tcl
	return
    }

    set_variables_after_query

    if ![empty_string_p $release_date] {
	set actually_released checked
    }
}




# emit the page contents

ns_puts "[ad_header "Edit Release \"$release_name\""]"

ns_puts "<h2>Edit Release \"$release_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list release-view.tcl?[export_url_vars release_id] "View Release"] "Edit Release"]
<hr>
"


# include the shared HTML form

ns_adp_include "release-form.adp" "Update Release" "release-edit-2.adp"



ns_puts "[glassroom_footer]"

%>

