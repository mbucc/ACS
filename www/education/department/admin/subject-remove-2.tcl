#
# /www/education/department/subject-remove-2.tcl
#
# by randyg@arsdigita, aileen@mit.edu, January 2000
#
# this page removes a subject form the deparement/subject
# mapping table
#

ad_page_variables {
    subject_id
}

if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li>You must include a subject identification number."
    return
}


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set department_id [lindex $id_list 1]

# let's delete the subject from the mapping table

ns_db dml $db "delete from edu_subject_department_map where subject_id = $subject_id and department_id = $department_id"

ns_db releasehandle $db 

ad_returnredirect ""
