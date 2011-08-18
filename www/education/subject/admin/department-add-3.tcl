#
# /www/education/subject/admin/department-add-3.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com January 2000
#
# this page finally puts the departmental data into the database

ad_page_variables {
    subject_id
    department_list
}

# department_list is a list of lists.
# the first element is the department id, the second element is the subject_name
# within the department and the third item is the department_name

set db [ns_db gethandle]

set user_id [edu_subject_admin_security_check $db $subject_id]

set exception_text ""
set exception_count 0

if {[empty_string_p subject_id]} {
    incr exception_count
    append exception_text "<li> You must include the departmet list"
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exceptiont_text
    return
}



ns_db dml $db "begin transaction"

foreach department $department_list {
    ns_db dml $db "insert into edu_subject_department_map (
                   department_id, 
                   subject_id,
                   grad_p,
                   subject_number)
                values (
                   [lindex $department 0],
                   $subject_id,
                   '[lindex $department 3]',
                   '[lindex $department 1]')"
}

ns_db dml $db "end transaction"

ns_db releasehandle $db

ad_returnredirect "index.tcl?subject_id=$subject_id"


