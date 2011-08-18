#
# /www/education/util/users/role-change-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, Januray 2000
#
# this changes the user's role in the group
#

ad_page_variables {
    {return_url ""}
    role
    user_id
}


set db [ns_db gethandle]

set exception_text ""
set exception_count 0

if {[empty_string_p $user_id]} {
    incr exception_count
    append exception_text "<li>You must provide an employee identification number for this page to be displayed."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set group_pretty_type [edu_get_group_pretty_type_from_url]

# right now, the proc above is only set up to recognize type 
# group and department and the proc must be changed if this page
# is to be used for URLs besides those.

if {[empty_string_p $group_pretty_type]} {
    ns_returnnotfound
    return
} else {

    if {[string compare $group_pretty_type class] == 0} {
	set id_list [edu_group_security_check $db edu_class "Manage Users"]
    } else {
	# it is a department
	set id_list [edu_group_security_check $db edu_department]
    }
}

set group_id [lindex $id_list 1]
set group_name [lindex $id_list 2]

ns_db dml $db "begin transaction"

##### aileen: this page does not delete the user's previous roles from
#### the group. a user should only have 1 role per group_id!
ns_db dml $db "delete from user_group_map where user_id=$user_id and group_id=$group_id"


# we do not check to see if the user is a member of the group because
# if they are not, this proc will make them a user of the group

ad_user_group_user_add $db $user_id $role $group_id

ns_db dml $db "end transaction"
ns_db releasehandle $db

if {[info exists return_url] && ![empty_string_p $return_url]} {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "/education/class/admin/users/one.tcl?user_id=$user_id"
}



