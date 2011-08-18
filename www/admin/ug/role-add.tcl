# $Id: role-add.tcl,v 3.0.4.1 2000/04/28 15:09:34 carsten Exp $
set_the_usual_form_variables

# group_id, role

set exception_count 0
set exception_text ""

if { ![info exists role] && [empty_string_p $role] } {
    incr exception_count
    append exception_text "<li>Please type in a role"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
}

set db [ns_db gethandle]

ad_user_group_role_add $db $group_id $role

ad_returnredirect "group.tcl?group_id=$group_id"

