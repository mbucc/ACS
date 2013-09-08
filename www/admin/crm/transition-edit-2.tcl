# /www/admin/crm/transition-edit-2.tcl

ad_page_contract {
    @param state_name
    @param next_state
    @cvs-id transition-edit-2.tcl,v 3.2.2.5 2000/07/21 03:56:35 ron Exp
} {
    state_name
    next_state
    transition_condition
}

set user_id [ad_maybe_redirect_for_registration]

set exception_count 0
set exception_text ""

if { [empty_string_p $transition_condition] } {
    incr exception_count
    append exception_text "<li>You must specify a transition condition.\n"
} else {
    # Check to see if the SQL fragment is valid.
    with_catch errmsg {
	# transition_condition can not be a bind variable, as it
	# is a sql clause by definition

	db_string get_user_count "select count(*) from users where crm_state = :state_name and ($transition_condition)"
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
    db_dml crm_update_transition "update crm_state_transitions 
set transition_condition = :transition_condition
where state_name = :state_name
and next_state = :next_state"
} {
    ad_return_warning "Database Error" "We encountered a database error while trying to edit
your new state transition.
<pre>
$errmsg
</pre>
[ad_admin_footer]"
}

db_release_unused_handles

ad_returnredirect "index"
