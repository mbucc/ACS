#
# /www/education/class/admin/users/student-info-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This places the the student information into the database
#

ad_page_variables {
    student_id
    student_account
    institution_id
}


set db [ns_db gethandle]

# make sure the person is authorized
set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]

set exception_text ""
set exception_count 0

if {[empty_string_p $student_id]} {
    incr exception_count
    append exception_text "<li>You must include the identification number for the student.\n"
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


# lets find out if these should be updates or inserts

if { [database_to_tcl_string $db "select count(field_value) from user_group_member_field_map where user_id = $student_id and group_id = $class_id and field_name = 'Institution ID'"] > 0} {
    
    # there is already a record so lets do an  update
    
    set institute_statement "update user_group_member_field_map
                      set field_value = [ns_dbquotevalue $institution_id
                    where group_id = $class_id 
                      and user_id = $student_id
                      and field_name = 'Institution ID'"
} else {
    set institute_statement "insert into user_group_member_field_map (group_id, user_id, field_name, field_value) values ($class_id, $student_id, 'Institution ID', [ns_dbquotevalue $institution_id])"
}


if { [database_to_tcl_string $db "select count(field_value) from user_group_member_field_map where user_id = $student_id and group_id = $class_id and field_name = 'Student Account'"] > 0} {
    
    # there is already a record so lets do an  update
    
    set account_statement "update user_group_member_field_map
                      set field_value = [ns_dbquotevalue $student_account]
                    where group_id = $class_id 
                      and user_id = $student_id
                      and field_name = 'Student Account'"
} else {

    set account_statement "insert into user_group_member_field_map (group_id, user_id, field_name, field_value) values ($class_id, $student_id, 'Student Account', [ns_dbquotevalue $student_account])"

}


# now that the information is checked, lets do the inserts

if [catch { ns_db dml $db "begin transaction"
            ns_db dml $db $institute_statement
            ns_db dml $db $account_statement
            ns_db dml $db "end transaction" } errmsg] {
		ad_return_error "database choked" "The database choked on your insert:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
You can back up, edit your data, and try again"
return
}
		
ns_db releasehandle $db

ad_returnredirect "student-info.tcl?student_id=$student_id"

