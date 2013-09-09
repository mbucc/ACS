# /www/bboard/admin-expired-threads-delete.tcl
ad_page_contract {
    deletes old threads

    @cvs-id admin-expired-threads-delete.tcl,v 3.1.6.4 2000/09/22 01:36:44 kevin Exp
} {
    topic
    topic_id:notnull,integer
}

# -----------------------------------------------------------------------------

if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[bboard_header "Deleting expired threads in $topic"]

<h2>Expired Threads</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic question and answer forum</a>

<hr>

<ul>
"

db_foreach old_threads "
select msg_id, one_line, sort_key
from   bboard 
where  topic_id = :topic_id
and    (posting_time + expiration_days) < sysdate
and    refers_to is null
order by sort_key $q_and_a_sort_order" {

    append page_content "<li>working on \"$one_line\" and its dependents... \n"
    set dependent_key_form [dependent_sort_key_form $sort_key]
    set dependent_ids [db_list dependents "
    select msg_id from bboard where sort_key like :dependent_key_form"]

    db_transaction {
    
	if {[bboard_file_uploading_enabled_p]} {	
	    set list_of_files_to_delete [db_list files "
	    select filename_stub from bboard_uploaded_files 
	    where msg_id IN ('[join $dependent_ids "','"]')"]

	    db_dml file_delete "
	    delete from bboard_uploaded_files 
	    where msg_id in (:msg_id, '[join $dependent_ids "','"]' )"

	    # ADD THE ACTUAL DELETION OF FILES
	    if { [llength $list_of_files_to_delete] > 0 } {
		ns_atclose "bboard_delete_uploaded_files $list_of_files_to_delete"
	    }
	}
	
	db_dml alerts_delete "
	delete from bboard_thread_email_alerts 
	where thread_id in ( :msg_id,'[join $dependent_ids "','"]' )"

	db_dml msg_delete "
	delete from bboard 
	where msg_id in ( :msg_id,'[join $dependent_ids "','"]' )"

	append page_content "success! (killed [llength $dependent_ids] dependents)\n"
    } on_error {
	append page_content "failed.  Database choked up \"$errmsg\">
    }
} if_no_rows {
    append page_content "there are no expired threads right now; so none were deleted"
}

append page_content "

</ul>


[bboard_footer]
"

doc_return  200 text/html $page_content