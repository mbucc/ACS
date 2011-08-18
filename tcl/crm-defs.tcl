# $Id: crm-defs.tcl,v 3.1 2000/02/26 12:55:28 jsalz Exp $
#
# /tcl/crm-defs.tcl
#
# by jsc@arsdigita.com in October 1999
# 
# definitions related to the CRM (customer relationship management) module
#

util_report_library_entry

proc_doc crm_run_state_machine {} {Updates all the users' crm_state information.} {
    set dbs [ns_db gethandle subquery 2]
    set db [lindex $dbs 0]
    set sub_db [lindex $dbs 1]

    ns_log Notice "Starting CRM update"

    set now [database_to_tcl_string $db "select to_char(sysdate, 'YYYYMMDDHH24MISS') from dual"]

    # Sleep for a second, so that we don't inadvertently step on our toes below.
    ns_sleep 1

    set selection [ns_db select $db "select state_name, next_state, transition_condition
from crm_state_transitions
order by triggering_order"]

    with_transaction $sub_db {
	while { [ns_db getrow $db $selection] } {
	    set_variables_after_query
	    
	    ns_db dml $sub_db "update users
set crm_state = '$next_state', crm_state_entered_date = sysdate
where crm_state = '$state_name'
and crm_state_entered_date < to_date('$now', 'YYYYMMDDHH24MISS')
and ($transition_condition)"
        }
    } {
        ns_log Bug "CRM update failed: $errmsg"
    }


    ns_db releasehandle $db
    ns_db releasehandle $sub_db
    ns_log Notice "CRM update done"
}

ns_share -init {set crm_update_scheduled 0} crm_update_scheduled

if { !$crm_update_scheduled && ![philg_development_p] } {
    set crm_update_scheduled 1
    ns_log Notice "Scheduling crm update with ns_schedule..."
    ad_schedule_proc -thread t [expr 3600 * [ad_parameter UpdatePeriodHours crm 24]] crm_run_state_machine
} else {
    ns_log Notice "crm update already scheduled"
}

util_report_successful_library_load
