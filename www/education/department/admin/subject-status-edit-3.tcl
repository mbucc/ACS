#
# /www/education/department/admin/subject-status-edit-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to change the subject number and 
# graduate status of the class
# this page does the actual insert
#

ad_page_variables {
    subject_id
    subject_number
    grad_p
}


if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li>You must include a subject identification number."
    return
}

if {[empty_string_p $subject_number]} {
    ad_return_complaint 1 "<li>You must include a subject number."
    return
}


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set department_id [lindex $id_list 0]

ns_db dml $db "update edu_subject_department_map 
                  set subject_number = '$QQsubject_number',
                      grad_p = '$grad_p'
                where subject_id = $subject_id 
                  and department_id = $department_id"


ns_db releasehandle $db

ad_returnredirect ""












