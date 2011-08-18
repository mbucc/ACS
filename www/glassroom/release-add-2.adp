<%
# release-add-2.adp -- add a new release to the glassroom_releases table
#                      (this is an ADP as opposed to a .tcl file so that 
#                      it's consistent naming with domain-add.adp)

set_the_usual_form_variables

# Expects release_id, module_id, release_date, anticipated_release_date,
#         release_name, and manager
#
# This also handles a 'search' button for looking up a user.
#      find_manager
# If this is set, then that's the action that triggered us

# release_date and anticipated_release_date are the magical AOLserver date/time format


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

# unpack the dates

if [catch { ns_dbformvalue [ns_conn form] release_date date release_date } errmsg] {
    ad_return_complaint 1 "<li> The release date wasn't well-formed"
    ns_adp_abort
}

if [catch { ns_dbformvalue [ns_conn form] anticipated_release_date date anticipated_release_date } errmsg] {
    ad_return_complaint 1 "<li> The anticipated release date wasn't well-formed"
    ns_adp_abort
}


# redirect to a search page if appropriate


if [info exists find_manager] {
    ns_set put [ns_conn form] release_date $release_date
    ns_set put [ns_conn form] anticipated_release_date $anticipated_release_date
    ns_adp_include user-search.adp "Who Owns It" "manager" "/glassroom/release-add.adp" [list release-add.adp "Add Software Release"] "release_id module_id release_date anticipated_release_date release_name manager search_token actually_released"
    ns_adp_break
}




# if we get here, we add it to the database

# check for bad input

if ![info exists manager] {
    set manager "NULL"
}

set happy_p [glassroom_check_release_args $release_date $anticipated_release_date $release_name $manager]

if $happy_p {

    if ![info exists actually_released] {
	set release_date "NULL"
    } else {
	set release_date "'$release_date'"
    }

    set insert_sql "
    insert into glassroom_releases
      (release_id, module_id, release_date, anticipated_release_date, release_name, manager)
    values
      ($release_id, $module_id, 
       to_date($release_date, 'yyyy-mm-dd'),
       to_date('$anticipated_release_date', 'yyyy-mm-dd'),
       '$QQrelease_name', $manager)"

    set db [ns_db gethandle]
    ns_db dml $db "$insert_sql"
    ns_db releasehandle $db


    # and redirect back to index.tcl so folks can see the new release

    ad_returnredirect "index.tcl"
}

%>

