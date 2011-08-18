# /admin/crm/initial-state-assign.tcl
# by jsc@arsdigita.com

# Assign the initial state by updating initial_state_p in crm_states,
# assigning all unassigned users to that state,
# and by altering the crm_state field in the users table.

set_the_usual_form_variables
# state

set db [ns_db gethandle]

with_transaction $db {
    ns_db dml $db "update crm_states set initial_state_p = decode(state_name, '$QQstate', 't', 'f')"
    ns_db dml $db "update users set crm_state = '$QQstate' where crm_state is null"
    ns_db dml $db "alter table users modify (crm_state default '$QQstate')"
} {
    ad_return_error "Error setting initial state" "A database error
occured while attempting to set the initial state for CRM:
<pre>
$errmsg
</pre>
"
    return
}

ad_returnredirect "index.tcl"