# /www/admin/crm/run-states.tcl

ad_page_contract {
    Run the crm state machine
    @cvs-id run-states.tcl,v 3.0.12.8 2000/07/21 03:56:35 ron Exp
} {}

# Note this page uses ReturnHeaders and ns_write on 
# purpose, as the purpose of this page is keep the
# user updated on the state machine progress.

ReturnHeaders
ns_write "[ad_admin_header "Update User States"]
<h2>Update User States</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Update User States"]
<hr>
"

set now [db_string get_date "select to_char(sysdate, 'YYYYMMDDHH24MISS') from dual"]

ns_sleep 1

db_foreach crm_finite_machine_get_states "select 
state_name, next_state, transition_condition, triggering_order
from crm_state_transitions
order by triggering_order" {

	ns_write "$state_name to $next_state:"
	 
       db_dml crm_update_state "update users
set crm_state = :next_state, crm_state_entered_date = sysdate
where crm_state = :state_name
and crm_state_entered_date < to_date(:now, 'YYYYMMDDHH24MISS')
and ($transition_condition)"


        ns_write "[db_resultrows]<br>\n"
    
}

db_release_unused_handles
ns_write "[ad_admin_footer]"




