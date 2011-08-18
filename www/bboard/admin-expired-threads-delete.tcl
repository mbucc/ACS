# $Id: admin-expired-threads-delete.tcl,v 3.0 2000/02/06 03:32:53 ron Exp $
set_the_usual_form_variables

# topic, topic_id

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}


# we found subject_line_suffix at least 
set_variables_after_query

ReturnHeaders

ns_write "<html>
<head>
<title>Deleting expired threads in $topic</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Expired Threads</h2>

in the <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>


"

set threads_to_nuke [database_to_tcl_list_list $db "select msg_id, one_line, sort_key
from bboard 
where topic_id = $topic_id
and (posting_time + expiration_days) < sysdate
and refers_to is null
order by sort_key $q_and_a_sort_order"]

ns_write "<ul>\n"

set counter 0

foreach elt $threads_to_nuke {
    incr counter
    set msg_id [lindex $elt 0]
    set one_line [lindex $elt 1]
    set sort_key [lindex $elt 2]
    ns_write "<li>working on \"$one_line\" and its dependents... \n"
    set dependent_key_form [dependent_sort_key_form $sort_key]
    set dependent_ids [database_to_tcl_list $db "select msg_id from bboard where sort_key like '$dependent_key_form'"]

    with_transaction $db {
    
    if {[bboard_file_uploading_enabled_p]} {	
	set list_of_files_to_delete [database_to_tcl_list $db "select filename_stub from bboard_uploaded_files where msg_id IN ('[join $dependent_ids "','"]')"]

	ns_db dml $db "delete from bboard_uploaded_files where msg_id in ('$msg_id', '[join $dependent_ids "','"]' )"

	# ADD THE ACTUAL DELETION OF FILES
	if { [llength $list_of_files_to_delete] > 0 } {
	    ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
	}
    }

	ns_db dml $db "delete from bboard_thread_email_alerts where thread_id in ( '$msg_id','[join $dependent_ids "','"]' )"

	ns_db dml $db "delete from bboard where msg_id in ( '$msg_id','[join $dependent_ids "','"]' )"
	ns_write "success! (killed [llength $dependent_ids] dependents)\n"
    } {
	ns_write "failed.  Database choked up \"$errmsg\">
    }
}

if { $counter == 0 } {
    ns_write "there are no expired threads right now; so none were deleted"
}

ns_write "

</ul>


[bboard_footer]
"
