# /www/admin/crm/initial-state-assign.tcl

ad_page_contract {
    Assign the initial state by updating initial_state_p in crm_states,
    assigning all unassigned users to that state,
    and by altering the crm_state field in the users table.
    @param state
    @author jsc@arsdigita.com
    @cvs-id initial-state-assign.tcl,v 3.3.2.6 2000/08/08 21:54:30 akk Exp
} {
    state
}

db_transaction  {

    db_dml crm_state_initialize "update crm_states set initial_state_p = decode(state_name, :state, 't', 'f')"
    db_dml crm_state_upgrade_null_users "update users set crm_state = :state, CRM_STATE_ENTERED_DATE=sysdate where crm_state is null"
    # it is a shame that bind variables don't work for ddl statements afaict -akk
    db_dml crm_state_user_table_default_update "alter table users modify (crm_state default '[DoubleApos $state]')" 

} on_error {
    ad_return_error "Error setting initial state" "A database error
occured while attempting to set the initial state for CRM:
<pre>
$errmsg
</pre>
"
    return
}

db_release_unused_handles

ad_returnredirect "index"
