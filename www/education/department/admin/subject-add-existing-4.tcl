#
# /www/education/department/admin/subject-add-existing-4.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add an existing subject to the department
# this does the actual insert

ad_page_variables {
    subject_id
    {subject_number ""}
    {grad_p f}
}


if {[empty_string_p $subject_id]} {
    ad_return_complaint 1 "<li>You must include a subject identification number."
    return
}


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]
set department_name [lindex $id_list 2]


# lets make sure that the subject_id provided maps to the departments

set insert_statement "insert into edu_subject_department_map (
                    subject_id,
                    subject_number,
                    grad_p,
                    department_id)
                values (
                    $subject_id,
                   '$QQsubject_number',
                   '$grad_p',
                    $department_id)"    


if { [catch { ns_db dml $db $insert_statement } errmsg ] } {
    # something went wrong.  
    if {[database_to_tcl_string $db "select count(subject_id) from edu_subject_department_map where subject_id = $subject_id and department_id = $department_id" > 0]} {
	# mapping was already in the tables
	ns_db releasehandle $db
	ad_returnredirect ""
    } else {
	ad_return_error "database choked" "The database choked on your insert:
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>
	You can back up, edit your data, and try again"
    }
    return
}
                              
# insert went OK

ns_db releasehandle $db

ad_returnredirect ""









