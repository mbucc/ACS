<%
# procedure-edit.adp -- edit a software procedure in the glassroom_procedures table.
#                    This file is an ADP so that we can ns_adp_include the 
#                    entry/editing form


set_the_usual_form_variables

# Expects procedure_id, or all of the requisite form data
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

set db [ns_db gethandle]

    
if [info exists search_token] {
    # means we're on a return-trip from user searching
    if { $search_token == "responsible_user" } {
	set responsible_user $user_id_from_search
    }

} else {
    
    # snarf the module information
    
    set select_sql "
    select procedure_description, responsible_user, responsible_user_group, max_time_interval, importance
      from glassroom_procedures
     where procedure_name = '$QQprocedure_name'"
    
    set selection [ns_db 1row $db $select_sql]

    if { [empty_string_p $selection] } {
	
	# if it's not there, just redirect them to the index page
	# (if they hacked the URL, they get what they deserve, if the
	# the procedure has been deleted, they can see the list of valid procedures)
	ad_returnredirect index.tcl
	return
    }

    set_variables_after_query
}




# emit the page contents

ns_puts "[ad_header "Edit Procedure \"$procedure_name\""]"

ns_puts "<h2>Edit Procedure \"$procedure_name\"</h2>
in [ad_context_bar [list index.tcl Glassroom] [list procedure-view.tcl?[export_url_vars procedure_id] "View Procedure"] "Edit Procedure"]
<hr>
"


# include the shared HTML form

ns_adp_include "procedure-form.adp" "Update Procedure" "procedure-edit-2.adp"



ns_puts "[glassroom_footer]"

%>

