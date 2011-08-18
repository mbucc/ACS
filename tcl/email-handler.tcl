# $Id: email-handler.tcl,v 3.1 2000/02/26 12:55:29 jsalz Exp $
#
# email-handler.tcl
#
# by hqm@arsdigita.com June 1999

util_report_library_entry

#
# Scan the incoming email queue, looking for messages
#

# Edit this procedure to add a new procedure dispatch
proc map_email_queue_message {db destaddr msg} {
    set pairs [ad_parameter_all_values_as_list DispatchPair "email-queue"]
    foreach pair $pairs {
	set pair_list [split $pair "|"]
	set tag [lindex $pair_list 0]
	set tcl_proc_to_invoke [lindex $pair_list 1]
	if { [string compare $destaddr $tag] == 0 } {
	    $tcl_proc_to_invoke $db $msg
	    return ""
	}
    } 
    ns_log Notice "map_email_queue_message couldn't find anything to do with a tag of \"$destaddr\"
Message:
$msg
"
}

################################################################

proc debug_email_queue {} {
    ns_log Notice "process ticket queue would have run!"
}

proc process_email_queue {} {
    set db_pools [ns_db gethandle subquery 1]
    set db [lindex $db_pools 0]
    # loop over queue, running process_ticket_message $db $message
    with_transaction $db {
	set selection [ns_db select $db "select destaddr, id, content from incoming_email_queue"]
	set emails {}
	while { [ns_db getrow $db $selection] } { 
	    set_variables_after_query
	    lappend emails [list $id $content]
	}

	foreach entry $emails {
	    set id [lindex $entry 0]
	    set content [lindex $entry 1]
	    ns_log Notice "email queue processing queued_msg $id"
	    map_email_queue_message $db $destaddr $content
	    ns_db dml $db "delete from incoming_email_queue where id = $id"
	    ns_log Notice "email queue deleted queued_msg $id"
	}
    } {
	ns_log Notice "email queue processing; transaction ABORTED!"
	global errorInfo errorCode
	ns_log Notice $errorInfo
	return
    }
}

################################################################
# Use shared variable to keep an extra scheduling from
# happening when script is re-sourced

ns_share -init {set email_scheduler_installed 0} email_scheduler_installed

if {!$email_scheduler_installed} {
    set email_scheduler_installed 1
    set interval [ad_parameter QueueSweepInterval "email-queue" 1800]
    ns_log Notice "email-handler.tcl scheduling process_email_queue to run every $interval seconds."
    ad_schedule_proc -thread t $interval process_email_queue
}

util_report_successful_library_load
