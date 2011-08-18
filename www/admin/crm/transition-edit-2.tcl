# $Id: transition-edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:32 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}

set_the_usual_form_variables
# state_name, next_state, transition_condition

set exception_count 0
set exception_text ""

set db [ns_db gethandle]

if { [empty_string_p $transition_condition] } {
    incr exception_count
    append exception_text "<li>You must specify a transition condition.\n"
} else {
    # Check to see if the SQL fragment is valid.
    with_catch errmsg {
	database_to_tcl_string $db "select count(*) from users where crm_state = '$QQstate_name' and ($transition_condition)"
    } {
	incr exception_count
	append exception_text "<li>Your SQL was invalid: <pre>$errmsg</pre>\n"
    }
}


if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

with_catch errmsg {
    ns_db dml $db "update crm_state_transitions 
set transition_condition = '$QQtransition_condition'
where state_name = '$QQstate_name'
and next_state = '$QQnext_state'"
} {
    ad_return_warning "Database Error" "We encountered a database error while trying to edit
your new state transition.
<pre>
$errmsg
</pre>
[ad_admin_footer]"
}

ad_returnredirect "index.tcl"