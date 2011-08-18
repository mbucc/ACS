#
# /www/education/class/task-turn-in-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this file updates the edu_student_tasks table to reflect the uploaded file
# (aileen@mit.edu) - notice we don't insert until this last page - this is
# to protect against users backing up in previous pages b/c the file stuff 
# we do there isn't 100% fool-proof. so we update our tables here after we are
# sure that the file insert were completed w/o error 

ad_page_variables {
    file_id
    task_id
    {return_url index.tcl}
}    


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Submit Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

# lets make sure the student has write permission on this file.  If they do not
# then the file obviously does not belong to them

if {![database_to_tcl_string $db "select decode(ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS'),'t',1,0) from fs_versions_latest where file_id = $file_id"]} {

    # this only happens if someone is trying to do url surgery so lets try to 
    # scare them a little bit.

    ad_return_complaint 1 "<li>You are not authorized to claim this file as your own.  You really should think about the fact that you are trying to claim someone else's work as your own.  This has been recorded and the instructor will be notified if you try to do this again. $file_id"
    return
}


set insert_sql "insert into edu_student_answers (
       student_id,
       task_id,
       file_id,
       last_modified,
       modified_ip_address,
       last_modifying_user)
    values (
       $user_id,
       $task_id,
       $file_id,
       sysdate,
       '[ns_conn peeraddr]',
       $user_id)"


if {[catch { ns_db dml $db $insert_sql } errmsg] } {
    # insert failed; let's see if it was because of duplicate submission
    if {[database_to_tcl_string $db "select count(task_id) from edu_student_answers where task_id = $task_id and student_id = $user_id"] > 0} {
	# it was a double click so redirect the user
	ns_db releasehandle $db
	ad_returnredirect $return_url
    } else {
	ns_log Error "[edu_url]class/task-turn-in-2.tcl choked:  $errmsg"
	ad_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>
	"
	return
    }
}


ns_db releasehandle $db

ad_returnredirect $return_url






