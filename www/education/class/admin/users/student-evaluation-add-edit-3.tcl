#
# /www/education/class/admin/users/student-evaluation-add-edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page enters the evaluation into the database
#


ad_page_variables {
    student_id
    task_id
    {return_url ""}
    evaluation_id
    {grade ""}
    {comments ""}
    {show_student_p t}
    evaluation_type
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set grader_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]



if {[database_to_tcl_string $db "select count(evaluation_id) from edu_student_evaluations where evaluation_id = $evaluation_id"] == 0} {
    # this is an add

    ns_db dml $db "insert into edu_student_evaluations (
     evaluation_id,
     grader_id,
     student_id,
     class_id,
     task_id,
     evaluation_type,
     grade,
     comments,
     show_student_p,
     evaluation_date,
     last_modified,
     last_modifying_user,
     modified_ip_address)
  values (
     $evaluation_id,
     $grader_id,
     $student_id,
     $class_id,
     [ns_dbquotevalue $task_id],
     [ns_dbquotevalue $evaluation_type],
     [ns_dbquotevalue $grade],
     [ns_dbquotevalue $comments],
     '$show_student_p',
     sysdate,
     sysdate,
     $grader_id,
     '[ns_conn peeraddr]')"

} else {
    # this is an edit.

    ns_db dml $db "update edu_student_evaluations 
     set grader_id = $grader_id,
         grade = [ns_dbquotevalue $grade],
         comments = [ns_dbquotevalue $comments],
         show_student_p = '$show_student_p',
         evaluation_date = sysdate,
         evaluation_type = [ns_dbquotevalue $evaluation_type]
         last_modifying_user = $grader_id,
         last_modified = sysdate,
         modified_ip_address = '[ns_conn peeraddr]'
   where evaluation_id = $evaluation_id"
}

ns_db releasehandle $db

if {[info exists return_url] && ![empty_string_p $return_url]} {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "student-info.tcl?student_id=$student_id"
}










