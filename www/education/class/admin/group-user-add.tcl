#
# /www/education/class/admin/group-user-add.tcl
#
# by randyg@arsdigita.com January 2000
#
# this page adds a user to a group
#

ad_page_variables {
    {user_id ""}
    {student_id ""}
    group_id
    {role member}
    {return_url ""}
}

# either user_id or student_id must be not null


if {[empty_string_p $user_id]} {
    if {[empty_string_p $student_id]} {
	ad_return_complaint 1 "<li>You must provide a user to be deleted from this group."
	return
    } else {
	set user_id $student_id
    }
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]

# need to make sure that the group is part of this class
if {[database_to_tcl_string $db "select count(group_id) from user_groups where group_id = $group_id and (group_id = $class_id or parent_group_id = $class_id)"] == 0} {
    ad_return_complaint 1 "<li>The group that you are trying to add the user to is not a member of this class."
    return
}


# don't need to do a double-click check because the proc below does it 
# for us

ad_user_group_user_add $db $user_id $role $group_id

ns_db releasehandle $db

ad_returnredirect $return_url
