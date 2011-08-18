#
# /www/education/class/admin/task-add-4.tcl
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
    {return_url ""}
}    


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

# lets make sure the task belongs to this class
if {[database_to_tcl_string $db "select count(task_id) from edu_student_tasks where task_id = $task_id and class_id = $class_id"] == 0} {
    ad_return_compalint 1 "<li>You are not authorized to edit this task."
    return
}

ns_db dml $db "update edu_student_tasks set file_id = $file_id where task_id = $task_id"

ns_db releasehandle $db

ad_returnredirect $return_url



