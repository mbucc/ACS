<%
# release-edit-2.adp -- modify a procedure in the glassroom_procedures table.
#

set_the_usual_form_variables

# Expects procedure_name, procedure_description, old_procedure_name, responsible_user, responsible_user_group, max_time_interval, importance
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
    ns_adp_include user-search.adp "Responsible User" "responsible_user" "/glassroom/procedure-edit.adp" [list procedure-edit.adp "Edit Procedure"] "procedure_name procedure_description old_procedure_name responsible_user responsible_user_group max_time_interval importance search_token"
    ns_adp_break
}



# if we get here, we update it in the database

# check for bad input

if ![info exists responsible_user] {
    set responsible_user ""
}

if ![info exists responsible_user_group] {
    set responsible_user_group ""
}



set happy_p [glassroom_check_procedure_args $procedure_name $procedure_description $responsible_user $responsible_user_group $max_time_interval $importance]

if $happy_p {

    if [empty_string_p $responsible_user] {
	set responsible_user "NULL"
    }

    if [empty_string_p $responsible_user_group] {
	set responsible_user_group "NULL"
    }

    if [empty_string_p $max_time_interval] {
	set max_time_interval "NULL"
    }

    set update_sql "
    update glassroom_procedures
    set
        procedure_name='$QQprocedure_name',
        procedure_description='$QQprocedure_description',
        responsible_user=$responsible_user,
        responsible_user_group=$responsible_user_group,
        max_time_interval=$max_time_interval,
        importance=$importance
    where procedure_name='$QQold_procedure_name'"

    set db [ns_db gethandle]
    ns_db dml $db "$update_sql"
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new release list

    ad_returnredirect "index.tcl"
}

%>
