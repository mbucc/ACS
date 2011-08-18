#
# /www/education/department/admin/subject-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this allows an admin to add a subject to the department
# this page does the actual insert

ad_page_variables {
    subject_name
    subject_id
    {description ""}
    {credit_hours ""}
    {prerequisites ""}
    {professors_in_charge ""}
    {subject_number ""}
    {grad_p f}
}


# check and make sure we received all of the input we were supposed to

set exception_text ""
set exception_count 0

if {[empty_string_p $subject_name]} {
    append exception_text "<li> You must provide a name for the new subject."
    incr exception_count
}

if {[empty_string_p $subject_id]} {
    append exception_text "<li> You must provide an identification number for the new subject."
    incr exception_count
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

# set the user and group information
set id_list [edu_group_security_check $db edu_department]
set user_id [lindex $id_list 0]
set department_id [lindex $id_list 1]


set subject_insert "insert into edu_subjects (
subject_id,
subject_name,
description,
credit_hours,
prerequisites,
professors_in_charge,
last_modified,
last_modifying_user,
modified_ip_address)
values (
$subject_id,
'$QQsubject_name',
'$QQdescription',
'$QQcredit_hours',
'$QQprerequisites',
'$QQprofessors_in_charge',
sysdate,
$user_id,
'[ns_conn peeraddr]')"


set department_insert "insert into edu_subject_department_map (
subject_id,
subject_number,
grad_p,
department_id)
values (
$subject_id,
'$QQsubject_number',
'$grad_p',
$department_id)"


if [catch { ns_db dml $db "begin transaction"
            ns_db dml $db $subject_insert
            ns_db dml $db $department_insert
            ns_db dml $db "end transaction" } errmsg] {
		# something went wrong.  
    
		if {[database_to_tcl_string $db "select count(subject_id) from edu_subjects where subject_id = $subject_id"] > 0 } {
		    # mapping was already in the tables
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











