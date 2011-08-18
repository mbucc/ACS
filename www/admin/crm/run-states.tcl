# $Id: run-states.tcl,v 3.0 2000/02/06 03:15:46 ron Exp $
set dbs [ns_db gethandle main 2]
set db [lindex $dbs 0]
set sub_db [lindex $dbs 1]

ReturnHeaders

ns_write "[ad_admin_header "Update User States"]
<h2>Update User States</h2>
[ad_admin_context_bar [list "/admin/crm" CRM] "Update User States"]
<hr>
"

set now [database_to_tcl_string $db "select to_char(sysdate, 'YYYYMMDDHH24MISS') from dual"]

ns_sleep 1

set selection [ns_db select $db "select state_name, next_state, transition_condition
from crm_state_transitions
order by triggering_order"]

with_transaction $sub_db {
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	ns_write "$state_name to $next_state:\n"
	ns_db dml $sub_db "update users
set crm_state = '$next_state', crm_state_entered_date = sysdate
where crm_state = '$state_name'
and crm_state_entered_date < to_date('$now', 'YYYYMMDDHH24MISS')
and ($transition_condition)"

	ns_write "[ns_ora resultrows $sub_db]<br>\n"
    }
} {
    ns_log Bug "CRM update failed: $errmsg"
}

ns_write [ad_admin_footer]