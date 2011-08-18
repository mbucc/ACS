# $Id: action-add.tcl,v 3.0.4.1 2000/04/28 15:09:24 carsten Exp $
set_the_usual_form_variables

# group_id, action

set exception_count 0
set exception_text ""

if { ![info exists action] && [empty_string_p $action] } {
    incr exception_count
    append exception_text "<li>Please type in a action"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
}

set db [ns_db gethandle]

ad_user_group_action_add $db $group_id $action

ad_returnredirect "group.tcl?group_id=$group_id"
