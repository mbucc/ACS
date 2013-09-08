# /tcl/crm-defs.tcl

ad_library {

    Procedures related to the CRM (customer relationship management) module

    @author Jin Choi (jsc@arsdigita.com)
    @cvs-id crm-defs.tcl,v 3.2.2.4 2000/09/14 07:36:30 ron Exp
}

proc_doc crm_run_state_machine {} {Updates all the users' crm_state information.} {
    ns_log Notice "Starting CRM update"

    set now [db_string getdate "select to_char(sysdate, 'YYYYMMDDHH24MISS') from dual"]
    
    # Sleep for a second, so that we don't inadvertently step on our toes below.
    ns_sleep 1
    
    if [catch {
	db_foreach crm_finite_machine_get_states "select 
	state_name, next_state, transition_condition
	from crm_state_transitions
	order by triggering_order" {
	 	    
	    db_dml crm_update_state "update users
	    set crm_state = :next_state, crm_state_entered_date = sysdate
	    where crm_state = :state_name
	    and crm_state_entered_date < to_date(:now, 'YYYYMMDDHH24MISS')
	    and ($transition_condition)"
	}
    } errmsg] {
	ns_log Bug "CRM update failed: $errmsg"
    }
    
    db_release_unused_handles
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
