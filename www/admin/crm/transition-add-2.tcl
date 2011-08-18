# $Id: transition-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:31 carsten Exp $
set user_id [ad_verify_and_get_user_id]
if { $user_id == 0 } {
    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]]"
    return
}

set_the_usual_form_variables
# from_state, to_state, after, transition_condition


set exception_count 0
set exception_text ""

set db [ns_db gethandle]

if { $from_state == $to_state } {
    incr exception_count
    append exception_text "<li>You cannot specify a transition from a state to itself.\n"
}

if { [empty_string_p $transition_condition] } {
    incr exception_count
    append exception_text "<li>You must specify a transition condition.\n"
} else {
    # Check to see if the SQL fragment is valid.
    with_catch errmsg {
	database_to_tcl_string $db "select count(*) from users where crm_state = '$QQfrom_state' and ($transition_condition)"
    } {
	incr exception_count
	append exception_text "<li>Your SQL was invalid: <pre>$errmsg</pre>\n"
    }
}


if { [database_to_tcl_string $db "select count(*) from crm_state_transitions
where state_name = '$QQfrom_state'
and next_state = '$QQto_state'"] } {
    incr exception_count
    append exception_text "<li>There is already a transition defined for those two states.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

with_transaction $db {
    ns_db dml $db "update crm_state_transitions 
set triggering_order = triggering_order + 1
where triggering_order > $after
and state_name = '$QQfrom_state'"
    
    ns_db dml $db "insert into crm_state_transitions (state_name, next_state, triggering_order, transition_condition) values ('$QQfrom_state', '$QQto_state', [expr $after + 1], '$QQtransition_condition')"
} {
    ad_return_warning "Database Error" "We encountered a database error while trying to create
your new state transition.
<pre>
$errmsg
</pre>
[ad_admin_footer]"
}

ad_returnredirect "index.tcl"