# tcl/email-handler.tcl


ad_library {
    
  Scan incoming email queue, and dispatch to assigned handler
  
    @author hqm@arsdigita.com 
    @cvs-id email-handler.tcl,v 3.4.2.6 2000/08/06 17:01:25 cnk Exp
}


#
# Scan the incoming email queue, looking for messages
#

# Edit this procedure to add a new procedure dispatch
proc map_email_queue_message {destaddr msg} {
    set pairs [ad_parameter_all_values_as_list DispatchPair "email-queue"]
    foreach pair $pairs {
	set pair_list [split $pair "|"]
	set tag [lindex $pair_list 0]
	set tcl_proc_to_invoke [lindex $pair_list 1]
	if { [string compare $destaddr $tag] == 0 } {
	    $tcl_proc_to_invoke $msg
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
    # loop over queue, running process_ticket_message $db $message
    # be careful to do this as small transactions to not hold up the
    # database too long.
    set id_list [db_list email_handler_get_ids "select id from incoming_email_queue"]

    foreach id $id_list {
	db_transaction {
	    db_1row get_message_info {
              select destaddr, content  from incoming_email_queue
		where id = :id
	    }
	    ns_log Notice "email queue processing queued_msg $id"
	    map_email_queue_message $destaddr $content
	    db_dml delete_from_queue "delete from incoming_email_queue where id = :id"
	    ns_log Notice "email queue deleted queued_msg $id"
	} on_error {
	    ns_log Notice "email queue processing; transaction ABORTED!"
	    global errorInfo errorCode
	    ns_log Notice $errorInfo
	}
    }
    # maybe remove anything still in the queue here, on the assumption that
    # failure above means the message is bogus
    db_release_unused_handles
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


