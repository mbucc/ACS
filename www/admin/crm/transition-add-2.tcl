# /www/admin/crm/transition-add-2.tcl

ad_page_contract {
    Add a crm transistion to the system
    @param from_state
    @param to_state
    @param after
    @param transition_condition
    @author Jin Choi
    @cvs-id transition-add-2.tcl,v 3.2.2.7 2000/07/26 19:25:00 lutter Exp
} {
    from_state:notnull
    to_state:notnull
    after
    transition_condition:allhtml,trim
}


set user_id [ad_maybe_redirect_for_registration]

set exception_count 0
set exception_text ""

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
	# Note: transition_condition is not a bind_vars
	# because we are testing the incoming sql transition.
	# In other words, by design, we need to allow flexible
	# in the structure of transition_condition.
	db_with_handle db {database_to_tcl_string $db "select count(*) from users where crm_state = '[DoubleApos $from_state]' and ($transition_condition)"} 
    } {
	incr exception_count
	append exception_text "<li>Your SQL was invalid: <pre>$errmsg</pre>\n"
    }
}


if { [db_string crm_transition_exists_p "select count(*) from crm_state_transitions
where state_name = :from_state
and next_state = :to_state"] } {
    incr exception_count
    append exception_text "<li>There is already a transition defined for those two states.\n"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

set after_plus_1 [expr $after + 1]

db_transaction  {

    db_dml crm_update_transition_triggering_order "update 
crm_state_transitions 
set triggering_order = triggering_order + 1
where triggering_order > :after
and state_name =:from_state"
    
    db_dml crm_insert_transition "insert into crm_state_transitions (state_name, next_state, triggering_order, transition_condition) values (:from_state, :to_state, :after_plus_1, :transition_condition)"
} on_error  {
    ad_return_warning "Database Error" "We encountered a database error while trying to create
your new state transition.
<pre>
$errmsg
</pre>
[ad_admin_footer]"
}

db_release_unused_handles
ad_returnredirect "index"
