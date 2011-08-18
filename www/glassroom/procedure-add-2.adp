<%
# procedure-add-2.adp -- add a new procedure to the glassroom_procedures table
#                      (this is an ADP as opposed to a .tcl file so that 
#                      it's consistent naming with domain-add.adp)

set_the_usual_form_variables

# Expects procedure_name, procedure_description, responsible_user, responsible_user_group, max_time_interval, importance
#
# This also handles a 'search' button for looking up a user.
#      find_responsible_user or find_responsible_group
# If this is set, then that's the action that triggered us


if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

# check for user

set user_id [ad_verify_and_get_user_id]


if { $user_id == 0 } {
    ad_returnredirect "/register.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}


# redirect to a search page if appropriate

if [info exists find_responsible_user] {
    ns_adp_include user-search.adp "Responsible User" "responsible_user" "/glassroom/procedure-add.adp" [list procedure-add.adp "Add Procedure"] "procedure_name procedure_description old_procedure_name responsible_user responsible_user_group max_time_interval importance search_token"
    ns_adp_break
}

if { ![info exists responsible_user] || [empty_string_p $responsible_user] } {
    set responsible_user ""
}

if { ![info exists responsible_user_group] || [empty_string_p $responsible_user_group] } {
    set responsible_user_group ""
}

if { ![info exists max_time_interval] || [empty_string_p $max_time_interval] } {
    set max_time_interval ""
}



set happy_p [glassroom_check_procedure_args $procedure_name $procedure_description $responsible_user $responsible_user_group $max_time_interval $importance]

if $happy_p {

    if [empty_string_p $max_time_interval] {
	set max_time_interval "NULL"
    }

    if [empty_string_p $responsible_user] {
	set responsible_user "NULL"
    }

    if [empty_string_p $responsible_user_group] {
	set responsible_user_group "NULL"
    }

    set insert_sql "
    insert into glassroom_procedures
        (procedure_name, procedure_description, responsible_user, responsible_user_group, max_time_interval, importance)
    values
        ('$QQprocedure_name', '$QQprocedure_description', $responsible_user, $responsible_user_group, $max_time_interval, $importance)"

    set db [ns_db gethandle]
    ns_db dml $db "$insert_sql"
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new release

    ad_returnredirect "index.tcl"
}

%>

