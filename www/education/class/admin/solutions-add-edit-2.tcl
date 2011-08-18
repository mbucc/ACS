#
# /www/education/class/admin/solutions-add-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this file should be redirected from upload-new.tcl
#

ad_page_variables {
    task_id
    file_id
    {final_return_url ""} 
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Tasks"]
set class_id [lindex $id_list 1]

# lets make sure that the task belongs to this class or one of its subgroups
if {[database_to_tcl_string $db "select count(class_id) from user_groups, edu_student_tasks where class_id = user_groups.group_id and (group_id = $class_id or parent_group_id = $class_id)"] == 0} {
    ad_return_complaint 1 "<li>You do not have permission to upload solutions for this task."
    return
}

set insert_sql "insert into edu_task_solutions (task_id, file_id) values ($task_id, $file_id)"

if {[catch { ns_db dml $db $insert_sql } errmsg] } {
    # insert failed; let's see if it was because of duplicate submission
    if {[database_to_tcl_string $db "select count(task_id) from edu_task_solutions where task_id = $task_id"] > 0} {
	# it was a double click so redirect the user
	ns_db releasehandle $db
	ad_returnredirect $final_return_url
    } else {
	ns_log Error "[edu_url]class/admin/exam-edit-2.tcl choked:  $errmsg"
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

ad_returnredirect $final_return_url
