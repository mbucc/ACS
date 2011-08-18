#
# /www/education/class/admin/task-delete-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page marks a task as inactive
#


ad_page_variables {
    task_id
    {return_url ""}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Delete Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# lets make sure that the task belongs to this class.  If it does not,
# let the user know that the input is not valid

set valid_id_p [database_to_tcl_string $db "select count(task_id) from edu_student_tasks where task_id = $task_id and class_id = $class_id"]

if {$valid_id_p == 0} {
    ad_return_complaint 1 "<li>The task that you have requested be delelted does not belong to this class."
    return
}


ns_db dml $db "update edu_student_tasks set active_p = 'f' where task_id = $task_id"

ns_db releasehandle $db

ad_returnredirect $return_url
