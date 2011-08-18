#
# /www/education/class/admin/group-user-remove.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page removes a user from a group after checking to make sure that
# the person trying to perform the action has permission to do so

ad_page_variables {
    {user_id ""}
    {student_id ""}
    group_id
    {return_url ""}
}

# requires one of user_id or student_id

if {[empty_string_p $user_id]} {
    if {[empty_string_p $student_id]} {
	ad_return_complaint 1 "<li>You must provide a user to remove from the group."
	return
    } else {
	set user_id $student_id
    }
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]

# want to check that the group is part of this class
if {[database_to_tcl_string $db "select count(class_id) from user_groups where group_id = $group_id and (group_id = $class_id or parent_group_id = $class_id)"] == 0} {
    ad_return_complaint 1 "<li>The group that you are trying to add the user to is not a member of this class."
    return
}

# don't need to do a double-click check because unmapping a student 
# multiple times does not cause a problem.

ns_db dml $db "delete from user_group_map where user_id = $user_id and group_id = $group_id"

ns_db releasehandle $db

ad_returnredirect $return_url
