<%
# module-add-2.adp -- add a new software module to the glassroom_modules
#                     table.



set_the_usual_form_variables

# Expects module_id, module_name, who_installed_it, who_owns_it, source
#         current_version
#
# This also handles two 'search' buttons for looking up folks:
#     find_who_owns_it and find_who_installed_it
# if either of these are set, then that's the action that triggered
# us

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

if [info exists find_who_owns_it] {
    ns_adp_include user-search.adp "Who Owns It" "who_owns" "/glassroom/module-add.adp" [list module-add.adp "Add Software Module"] "module_name who_installed_it who_owns_it source current_version search_token"
    ns_adp_break
}

if [info exists find_who_installed_it] {
    ns_adp_include user-search.adp "Who Installed It" "who_installed" "/glassroom/module-add.adp" [list module-add.adp "Add Software Module"] "module_name who_installed_it who_owns_it source current_version search_token"

    ns_adp_break
}


# if we get here, we add it to the database

# check for bad input

if ![info exists who_installed_it] {
    set who_installed_it "NULL"
}

if ![info exists who_owns_it] {
    set who_owns_it "NULL"
}

set happy_p [glassroom_check_module_args $module_name $who_installed_it $who_owns_it $source $current_version]


if $happy_p {
    set insert_sql "
    insert into glassroom_modules
      (module_id, module_name, source, current_version, who_installed_it, who_owns_it)
    values
      (glassroom_module_id_sequence.nextval, '$QQmodule_name', '$QQsource', '$QQcurrent_version', $who_installed_it, $who_owns_it)"

    set db [ns_db gethandle]
    ns_db dml $db "$insert_sql"
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new module list

    ad_returnredirect "index.tcl"
}

%>

