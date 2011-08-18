<%
# release-edit-2.adp -- modify a software release in the glassroom_releases
#                      table.


set_the_usual_form_variables

# Expects either nothing, or all the requisite form data when doing
#         a user search
#
# if search_token is set, that means that we've gotten to this page
# from a user search. expected token is "manager"



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
    ns_adp_include user-search.adp "Who Owns It" "manager" "/glassroom/release-edit.adp" [list release-edit.adp "Edit Software Release"] "release_id module_id release_date anticipated_release_date release_name manager search_token actually_released"
    ns_adp_break
}


# if we get here, we update it in the database

# check for bad input

if ![info exists manager] {
    set manager ""
}


set happy_p [glassroom_check_release_args $release_date $anticipated_release_date $release_name $manager]

if $happy_p {

    if ![info exists actually_released] {
	set release_date "NULL"
    } else {
	set release_date "'$release_date'"
    }

    if [empty_string_p $manager] {
	set manager "NULL"
    }

    set update_sql "
    update glassroom_releases
    set
        module_id = $module_id,
        release_date = to_date($release_date, 'yyyy-mm-dd'),
        anticipated_release_date = to_date('$anticipated_release_date', 'yyyy-mm-dd'),
        release_name = '$QQrelease_name',
        manager = $manager
    where release_id = $release_id"

    set db [ns_db gethandle]
    ns_db dml $db "$update_sql"
    ns_db releasehandle $db

    # and redirect back to index.tcl so folks can see the new release list

    ad_returnredirect "index.tcl"
}

%>

