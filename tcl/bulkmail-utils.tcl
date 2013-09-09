# tcl/bulkmail-utils.tcl

ad_library {
    
  Definitions for bulkmail multithreaded mail sending module
  
    @author gregh@arsdigita.com 
    @cvs-id bulkmail-utils.tcl,v 3.4.2.2 2000/07/21 08:17:52 hqm Exp
}


proc_doc bulkmail_simple_checksum { string } "Computes a trivial checksum for a string.  The checksum is the sum of the ascii values for each character of the string.

Note that we're not trying to bolt things down.  We're trying to keep the lazy,malicious attacker at bay.  Someone who really wanted to come after us would figure out anything we could reasonably do here." {

    set string_chars [split $string {}]

    set total 0
    foreach char $string_chars {
	scan $char "%c" value
	incr total $value
    }
    return $total
}

proc_doc bulkmail_key_code { bulkmail_id user_id } "Creates a bulkmail key code, which is of the format <bulkmail_id>A<user_id>B<ns_time>C<checksum>" {
    append output $bulkmail_id "A" $user_id "B" [ns_time]

    # For good measure, we'll calculate the checksum after making the letters
    # lowercase.  This could confuse the stupid attacker who's trying to
    # figure out what that number is.  Not much else.  We have to be sure
    # to do this when decoding, too.
    append output "C" [bulkmail_simple_checksum [string tolower $output]]

    return $output
}

proc_doc bulkmail_decode_key_code { key_code } "Given a key code, returns a list of the user_id and bulkmail_id.  Returns an empty list of there was an error." {
    set code_pieces [split $key_code "C"]

    if { [llength $code_pieces] == 0 } {
	return [list]
    }

    # First piece is the bulkmail_idAuser_idBns_time
    set user_content [lindex $code_pieces 0]

    # Second piece is the simple checksum
    set checksum [lindex $code_pieces 1]

    # Compare the checksum to the checksum of the user_content.  Be careful
    # to lower the string case.
    if { [bulkmail_simple_checksum [string tolower $user_content]] != $checksum } {
	return [list]
    }

    if { ![regexp -nocase {([0-9]+)A([0-9]+)B([0-9]+)} $user_content match bulkmail_id user_id time] } {
	return [list]
    }

    return "$bulkmail_id $user_id $time"
}

proc_doc bulkmail_ansi_current_time {} "Returns the current server time in ANSI format" {
    return [ns_fmttime [ns_time] "%Y-%m-%d %T"]
}

proc_doc bulkmail_begin { user_id { description "" } } "Initializes a new bulkmail instance.  Returns a bulkmail_id." {
    ns_share bulkmail_instances_mutex
    ns_share bulkmail_instance_mutexes_mutex
    ns_share bulkmail_instances
    ns_share bulkmail_instance_mutexes

    ns_mutex lock $bulkmail_instances_mutex
    if { [catch {
	set bulkmail_id [db_nextval "bulkmail_id_sequence"]
	db_dml add_new_instance "insert into bulkmail_instances (bulkmail_id, creation_date, creation_user, description) values (:bulkmail_id, sysdate, :user_id, :description])"
	
	ns_set put $bulkmail_instances $bulkmail_id [list 0 0]
    } errmsg] } {
	ns_log Notice "Error creating bulkmail instance: $errmsg"
    }
    ns_mutex unlock $bulkmail_instances_mutex

    ns_mutex lock $bulkmail_instance_mutexes_mutex
    if { [catch {
	ns_set put $bulkmail_instance_mutexes $bulkmail_id [ns_mutex create]
    } errmsg] } {
	ns_log Error "Error creating instance mutex: $errmsg\n"
    } 
    ns_mutex unlock $bulkmail_instance_mutexes_mutex
    
    return $bulkmail_id
}

proc_doc bulkmail_end {bulkmail_id } "Finalizes the info regarding the instance in bulkmail_instances" {
    ns_share bulkmail_db_flush_wait_event_mutex
    ns_share bulkmail_db_flush_wait_event
    ns_share bulkmail_instances_mutex
    ns_share bulkmail_instances
    ns_share bulkmail_finished_instances_mutex
    ns_share bulkmail_finished_instances
    ns_share bulkmail_instance_finished_event_mutex
    ns_share bulkmail_instance_finished_event
    ns_share bulkmail_message_queue_mutex
    
    # Spit out any lingering messages in the message queue.  If we have
    # anything still queued up, this will start them sending
    ns_mutex lock $bulkmail_message_queue_mutex
    catch {
	bulkmail_process_message_queue
    }
    ns_mutex unlock $bulkmail_message_queue_mutex

    # Wait until all of our messages have been sent.
    while (1) {
	# a bulkmail_instance_finished_event is triggered when all of an
	# instance's queued messages have been sent. Let's wait 10 seconds
	# on the event.  If it times out, we'll check to see if our instance
	# is finished, in case we missed the event (Thanks, Henry!)
	ns_event wait $bulkmail_instance_finished_event $bulkmail_instance_finished_event_mutex 10

	# Check to see if the instance we're waiting on is one that finished.
	ns_mutex lock $bulkmail_finished_instances_mutex
	if { [catch {
	    set n_sent [ns_set get $bulkmail_finished_instances $bulkmail_id]
	} errmsg] } {
	    ns_log Error "Error getting n_sent: $errmsg\n"
	}
	ns_log Notice "bulkmail_id: $bulkmail_id, n_sent: $n_sent\n"
	ns_mutex unlock $bulkmail_finished_instances_mutex

	# It was us, so let's finish up
#	if ![empty_string_p $n_sent] {
	    # Remove this instance from the list of finished instances
	    ns_mutex lock $bulkmail_finished_instances_mutex
	    catch {
		ns_set delkey $bulkmail_finished_instances $bulkmail_id
	    }
	    ns_mutex unlock $bulkmail_finished_instances_mutex

	    # We want to wait until the db_flush_wait proc is done flushing
	    # (the mutex for the wait event is unlocked) before we try 
	    # telling it to flush.  We'll do this by trying to lock the
	    # mutex.
	    ns_mutex lock $bulkmail_db_flush_wait_event_mutex
	    ns_mutex unlock $bulkmail_db_flush_wait_event_mutex

	    # Now trigger it.
	    ns_event set $bulkmail_db_flush_wait_event

	    # Remove this instance from bulkmail_instances
	    # This is placed far down, because it's called in
	    # bulkmail_db_flush_wait (so we need to make sure we don't
	    # call it until all our guys have made it.)
	    ns_mutex lock $bulkmail_instances_mutex
	    catch {
		ns_set delkey $bulkmail_instances $bulkmail_id
	    }
	    ns_mutex unlock $bulkmail_instances_mutex

	    # Wahoo! We're all clear kid!
	    break
#	}
    }

    # Once everything is done, let's finalize the data
    # It should have already been done by the db_flush proc, but just in
    # case, let's set it here.
    db_dml update_bulkmail_finish "update bulkmail_instances set end_date = sysdate where bulkmail_id = :bulkmail_id"

}

proc_doc bulkmail_register_thread { thread_id } "Register a thread in the thread_queue" {
    ns_share bulkmail_thread_queue_mutex
    ns_share bulkmail_thread_queue

    ns_mutex lock $bulkmail_thread_queue_mutex

    catch {
	lappend bulkmail_thread_queue $thread_id
    }

    ns_mutex unlock $bulkmail_thread_queue_mutex
}

proc_doc bulkmail_queue_message { message } "Handle the queuing of a message" {
    ns_share bulkmail_message_queue_mutex
    ns_share bulkmail_message_queue
    ns_share bulkmail_threads_sema

    ns_mutex lock $bulkmail_message_queue_mutex

    # Following the example in the docs, let's wrap all activities in
    # a catch so an error won't leave things locked
    if { [catch {
	lappend bulkmail_message_queue $message

	# Check to see if we've reached our threshold
	if { [llength $bulkmail_message_queue] >= [bulkmail_queue_threshold] } {
	    # If we have, we want to process the queue
	    bulkmail_process_message_queue

	}
    } errmsg] } {
	ns_log Notice "Caught error: $errmsg" 
    }
    ns_mutex unlock $bulkmail_message_queue_mutex

    bulkmail_record_queued_message [bulkmail_message_bulkmail_id $message]

}

# Danger lurks here.
# This is for INTERNAL use only.  The call to this proc must be done 
# only with a valid lock on bulkmail_message_queue_mutex
# This spawns a new mailer thread to go pound a server
proc bulkmail_process_message_queue {} {
    ns_share bulkmail_threads_sema
    ns_share bulkmail_message_queue

    # Wait for a thread to become available
    ns_sema wait $bulkmail_threads_sema

    # Spawn a thread to go send these messages
    ns_thread begindetached "bulkmail_sendmail {$bulkmail_message_queue} {[bulkmail_get_current_host]}"
    set bulkmail_message_queue [list]

    bulkmail_increment_threadcount
}    

proc_doc bulkmail_send {bulkmail_id user_id to from subject body {key_code ""} {extraheaders {}} {bcc {}}} "Add a message to the bulkmail queue" {

    if [empty_string_p $extraheaders] {
	set extraheaders [ns_set create extraheaders]
    }

    # We want to make it possible for a custom key_code to be used
    if [empty_string_p $key_code] {
	set key_code [bulkmail_key_code $bulkmail_id $user_id]
    }

    # We want to build our own reply-to
    ns_set idelkey $extraheaders "reply-to"
    set reply [bulkmail_reply_address $key_code]
    ns_set put $extraheaders "Reply-To" $reply

    # We also need to get the envelope sender
    set sender [bulkmail_sender_address $key_code]

    set message [bulkmail_build_message $bulkmail_id $user_id $sender $from $to $subject $body $extraheaders $bcc]

    bulkmail_queue_message $message
}

proc_doc bulkmail_record_sent_message { bulkmail_id user_id sent_date } "Record a sent message in the db_flush_queue and in the instance counts" {
    ns_share bulkmail_db_flush_queue_mutex
    ns_share bulkmail_db_flush_queue
    ns_share bulkmail_db_flush_wait_event
    ns_share bulkmail_instance_mutexes
    ns_share bulkmail_instances_mutex
    ns_share bulkmail_instances
    ns_share bulkmail_finished_instances_mutex
    ns_share bulkmail_finished_instances
    ns_share bulkmail_instance_finished_event

    ns_mutex lock $bulkmail_db_flush_queue_mutex
    catch {
	lappend bulkmail_db_flush_queue [list $bulkmail_id $user_id $sent_date]
    }
    ns_mutex unlock $bulkmail_db_flush_queue_mutex

    # tell the waiting thread that it's time to do its thing
    ns_event set $bulkmail_db_flush_wait_event

    # Next, let's take care of registering this in our instance message count
    set instance_mutex [ns_set get $bulkmail_instance_mutexes $bulkmail_id]

    ns_mutex lock $instance_mutex
    catch {
	ns_mutex lock $bulkmail_instances_mutex
	catch {
	    set instance_stats [ns_set get $bulkmail_instances $bulkmail_id]
	}
	ns_mutex unlock $bulkmail_instances_mutex

	# instance_stats is a two-item list: queued sent
	set queued_count [lindex $instance_stats 0]
	set sent_count [lindex $instance_stats 1]
	incr sent_count
	ns_mutex lock $bulkmail_instances_mutex
	catch {
	    ns_set delkey $bulkmail_instances $bulkmail_id
	    ns_set put $bulkmail_instances $bulkmail_id [list $queued_count $sent_count]
	}
	ns_mutex unlock $bulkmail_instances_mutex
    }
    ns_mutex unlock $instance_mutex

    if { $queued_count == $sent_count } {
	ns_mutex lock $bulkmail_finished_instances_mutex
	catch {
	    ns_set put $bulkmail_finished_instances $bulkmail_id $sent_count
	}
	ns_mutex unlock $bulkmail_finished_instances_mutex
	ns_event set $bulkmail_instance_finished_event
    }
}

proc_doc bulkmail_record_sent_messages { sent_messages } "Record sent messages in the db_flush_queue and in the instance counts" {
    ns_share bulkmail_db_flush_queue_mutex
    ns_share bulkmail_db_flush_queue
    ns_share bulkmail_db_flush_wait_event
    ns_share bulkmail_instance_mutexes
    ns_share bulkmail_instances_mutex
    ns_share bulkmail_instances
    ns_share bulkmail_finished_instances_mutex
    ns_share bulkmail_finished_instances
    ns_share bulkmail_instance_finished_event

    ns_mutex lock $bulkmail_db_flush_queue_mutex
    catch {
	lappend bulkmail_db_flush_queue $sent_messages
    }
    ns_mutex unlock $bulkmail_db_flush_queue_mutex

    # tell the waiting thread that it's time to do its thing
    ns_event set $bulkmail_db_flush_wait_event

    # Next, let's take care of registering this in our instance message count

    foreach message $sent_messages {
	set bulkmail_id [lindex $message 0]
	set instance_mutex [ns_set get $bulkmail_instance_mutexes $bulkmail_id]

	ns_mutex lock $instance_mutex
	catch {
	    ns_mutex lock $bulkmail_instances_mutex
	    catch {
		set instance_stats [ns_set get $bulkmail_instances $bulkmail_id]
	    }
	    ns_mutex unlock $bulkmail_instances_mutex

	    # instance_stats is a two-item list: queued sent
	    set queued_count [lindex $instance_stats 0]
	    set sent_count [lindex $instance_stats 1]
	    incr sent_count
	    ns_mutex lock $bulkmail_instances_mutex
	    catch {
		ns_set delkey $bulkmail_instances $bulkmail_id
		ns_set put $bulkmail_instances $bulkmail_id [list $queued_count $sent_count]
	    }
	    ns_mutex unlock $bulkmail_instances_mutex
	}
	ns_mutex unlock $instance_mutex

	if { $queued_count == $sent_count } {
	    ns_mutex lock $bulkmail_finished_instances_mutex
	    catch {
		ns_set put $bulkmail_finished_instances $bulkmail_id $sent_count
	    }
	    ns_mutex unlock $bulkmail_finished_instances_mutex
	    ns_event set $bulkmail_instance_finished_event
	}
    }
}

proc_doc bulkmail_record_queued_message { bulkmail_id } "Record a queued message in the instance message count" {
    ns_share bulkmail_instance_mutexes
    ns_share bulkmail_instances_mutex
    ns_share bulkmail_instances

    set instance_mutex [ns_set get $bulkmail_instance_mutexes $bulkmail_id]

    ns_mutex lock $instance_mutex
    catch {
	ns_mutex lock $bulkmail_instances_mutex
	catch {
	    set instance_stats [ns_set get $bulkmail_instances $bulkmail_id]
	}
	ns_mutex unlock $bulkmail_instances_mutex

	# instance_stats is a two-item list: queued sent
	set queued_count [lindex $instance_stats 0]
	set sent_count [lindex $instance_stats 1]
	incr queued_count
	ns_mutex lock $bulkmail_instances_mutex
	catch {
	    ns_set delkey $bulkmail_instances $bulkmail_id
	    ns_set put $bulkmail_instances $bulkmail_id [list $queued_count $sent_count]
	}
	ns_mutex unlock $bulkmail_instances_mutex
    }
    ns_mutex unlock $instance_mutex

}

proc_doc bulkmail_increment_threadcount {} "Increment the number of in-use threads.  This is actually a different variable than the completed threads variable, so that we won't block." {
    
    ns_share bulkmail_threads_spawned_mutex
    ns_share bulkmail_threads_spawned

    ns_mutex lock $bulkmail_threads_spawned_mutex
    catch {
	incr bulkmail_threads_spawned
    }
    ns_mutex unlock $bulkmail_threads_spawned_mutex
}

proc_doc bulkmail_decrement_threadcount {} "Decrement the count of in-use threads.  Used only for reporting matters.  We've already allowed a new thread to begin.  In actuality, we're incrementing the number completed, which will prevent us from blocking on a single shared value for the count.  It also allows us better reporting capabilities." {

    ns_share bulkmail_threads_completed_mutex
    ns_share bulkmail_threads_completed

    ns_mutex lock $bulkmail_threads_completed_mutex
    catch {
	incr bulkmail_threads_completed
    }
    ns_mutex unlock $bulkmail_threads_completed_mutex
}

proc_doc bulkmail_current_threadcount {} "Return the number of mailer threads current active.  This is the difference between bulkmail_threads_spawned and bulkmail_threads_completed." {
    ns_share bulkmail_threads_completed
    ns_share bulkmail_threads_spawned

    return [expr $bulkmail_threads_spawned - $bulkmail_threads_completed]
}

proc_doc bulkmail_db_flush_wait {} "Run forever, waiting to flush message info to the db" {
    ns_share bulkmail_db_flush_wait_event
    ns_share bulkmail_db_flush_wait_event_mutex
    ns_share bulkmail_db_flush_queue
    ns_share bulkmail_db_flush_queue_mutex
    ns_share bulkmail_instances_mutex
    ns_share bulkmail_instances

    # Loop forever, waiting for events requesting the flush of the queue.
    # TODO: probably want to have something trigger this to stop.  Maybe 
    # put a timeout on the wait, and have a check of a shared variable.
    while (1) {
	if { [catch {

	    # 2 second timeout
	    ns_event wait $bulkmail_db_flush_wait_event $bulkmail_db_flush_wait_event_mutex 2

	    ns_mutex lock $bulkmail_db_flush_queue_mutex
	    catch {
		set flush_queue $bulkmail_db_flush_queue
		set bulkmail_db_flush_queue [list]
	    }
	    ns_mutex unlock $bulkmail_db_flush_queue_mutex

	    if { [llength $flush_queue] > 0 } {
#		
#		db_transaction {
		foreach flushed_messages $flush_queue {
		    foreach flush_entry $flushed_messages {
			set bulkmail_id [lindex $flush_entry 0]
			set user_id [lindex $flush_entry 1]
			set sent_date [lindex $flush_entry 2]
#			db_dml bulkmail_log "insert into bulkmail_log (bulkmail_id, user_id, sent_date) values ($bulkmail_id, $user_id, to_date('$sent_date', 'YYYY-MM-DD HH24:MI:SS'))"
			
		    }

		    # Even though we're only reading, others may be writing or deleting
		    # our entry for update.  So, we need to lock this.
		    ns_mutex lock $bulkmail_instances_mutex
		    catch {
			set instance_stats [ns_set get $bulkmail_instances $bulkmail_id]
			# instance_stats is a two-item list: queued sent
			set queued_count [lindex $instance_stats 0]
			set sent_count [lindex $instance_stats 1]
		    }
		    ns_mutex unlock $bulkmail_instances_mutex

		    # We need to check if sent_count is empty.  This might occur
		    # if bulkmail_end finished up before db_flush_wait.
		    if ![empty_string_p $sent_count] {
#			db_dml update_n_sent "update bulkmail_instances set n_sent = $sent_count where bulkmail_id = $bulkmail_id"
		    }
		    
		}
#		}
#		db_release_unused_handles
	    }

	    
	} errmsg] } {
	    ns_log Notice "Caught error: $errmsg in bulkmail_db_flush_wait"
	}
	# Unlock the event's mutex
	ns_mutex unlock $bulkmail_db_flush_wait_event_mutex
    }
}

proc_doc bulkmail_get_current_host {} "Retrieves the smtp host to use and increments the index." {
    ns_share bulkmail_hosts_mutex
    ns_share bulkmail_hosts
    ns_share bulkmail_current_host_mutex
    ns_share bulkmail_failed_hosts
    ns_share bulkmail_failed_hosts_mutex
    ns_share bulkmail_current_host


    set hosts_reset_p 0

    ns_mutex lock $bulkmail_hosts_mutex

    catch {
	if {[llength $bulkmail_hosts] == 0} {
	    ns_log Error "bulkmail_get_current_host: bulkmail_hosts is an empty list. Resetting and sleeping 5 mins"
	    
	    set bulkmail_hosts [bulkmail_get_hostlist]
	    
	    catch { 
		ns_mutex lock $bulkmail_failed_hosts_mutex
		set bulkmail_failed_hosts [ns_set create -persist]
		set hosts_reset_p 1
	    }
	    ns_mutex unlock $bulkmail_failed_hosts_mutex	    
	    
	    ns_mutex lock $bulkmail_current_host_mutex
	    set bulkmail_current_host 0
	    ns_mutex unlock $bulkmail_current_host_mutex


	    if {$hosts_reset_p == 1} {
		ns_sleep 300
	    }

	}
    }
    ns_mutex unlock $bulkmail_hosts_mutex

    ns_mutex lock $bulkmail_current_host_mutex
    catch {
	incr bulkmail_current_host
	if { $bulkmail_current_host >= [llength $bulkmail_hosts] } {
	    set bulkmail_current_host 0
	}
	set current_host [lindex $bulkmail_hosts $bulkmail_current_host]
    }
    ns_mutex unlock $bulkmail_current_host_mutex

    return $current_host
}


proc_doc bulkmail_reset_hosts_list {} "Reset the list of mailer hosts to the default value" {
    ns_share bulkmail_hosts_mutex
    ns_share bulkmail_hosts
    ns_share bulkmail_current_host_mutex
    ns_share bulkmail_current_host
    ns_share bulkmail_failed_hosts
    ns_share bulkmail_failed_hosts_mutex

    set hosts_reset_p 0

    ns_mutex lock $bulkmail_hosts_mutex

    catch {
	ns_log Error "bulkmail_reset_hosts_list: Resetting hosts list"
	
	set bulkmail_hosts [bulkmail_get_hostlist]
	
	catch { 
	    ns_mutex lock $bulkmail_failed_hosts_mutex
	    set bulkmail_failed_hosts [ns_set create -persist]
	    set hosts_reset_p 1
	}
	ns_mutex unlock $bulkmail_failed_hosts_mutex	    
	
	ns_mutex lock $bulkmail_current_host_mutex
	set bulkmail_current_host 0
	ns_mutex unlock $bulkmail_current_host_mutex
    }
    
    ns_mutex unlock $bulkmail_hosts_mutex

    ns_mutex lock $bulkmail_current_host_mutex
    catch {
	incr bulkmail_current_host
	if { $bulkmail_current_host >= [llength $bulkmail_hosts] } {
	    set bulkmail_current_host 0
	}
	set current_host [lindex $bulkmail_hosts $bulkmail_current_host]
    }
    ns_mutex unlock $bulkmail_current_host_mutex

    return $current_host
}


proc_doc bulkmail_record_failed_host { host } "Records a host as failed.  If host has reached the acceptable failures threshhold, we delete it from the list of hosts." {
    ns_share bulkmail_failed_hosts_mutex
    ns_share bulkmail_failed_hosts
    ns_share bulkmail_hosts_mutex
    ns_share bulkmail_hosts
    ns_share bulkmail_current_host

    ns_log Notice "Processing failed host: $host"

    ns_mutex lock $bulkmail_failed_hosts_mutex
    catch {
	set n_failures [ns_set get $bulkmail_failed_hosts $host]
	if { [empty_string_p $n_failures] } {
	    set n_failures 0
	}
	incr n_failures
	ns_set delkey $bulkmail_failed_hosts $host
	ns_set put $bulkmail_failed_hosts $host $n_failures
    }
    ns_mutex unlock $bulkmail_failed_hosts_mutex

    if { $n_failures > [bulkmail_acceptable_host_failures] } {
	ns_mutex lock $bulkmail_hosts_mutex
	catch {
	    set list_index [lsearch -exact $bulkmail_hosts $host]
	    
	    # Check to see if we found this host (the index >= 0)
	    if { $list_index >= 0 } {
		set bulkmail_hosts [lreplace $bulkmail_hosts $list_index $list_index]
	    }
	}
	ns_mutex unlock $bulkmail_hosts_mutex
	ns_log Notice "Removed failed host: $host"
    }
}

proc_doc bulkmail_sweep_bounce_queue {} "Sweeps the bounce queue, handling bounced messages." {
    
    ns_log Notice "Sweeping bounce queue"

    set threshold [bulkmail_bounce_threshold]
    set bounce_dir [bulkmail_bounce_dir]
    set file_pattern "$bounce_dir/*"

    ns_log Notice "$bounce_dir\n$file_pattern"

    

    set n_bounces 0
    foreach file [glob -nocomplain $file_pattern] {
	ns_log Notice "Current file: $file"
	# file_name is file - bounce_dir + a slash (consumed by the zero-index)
	set file_name [string range $file [expr [string length $bounce_dir] + 1] end]
	set key_code [string toupper [lindex [split $file_name "@"] 0]]

	ns_log Notice "key_code: $key_code"
	set details [bulkmail_decode_key_code $key_code]

	ns_log Notice "file_name: $file_name\nDetails: $details"
	
	# See if we have garbage
	if { [llength $details] < 3 } {
	    # We can trash this file; it shouldn't be here
	    ns_unlink -nocomplain $file
	    continue
	}

	set bulkmail_id [lindex $details 0]
	set user_id [lindex $details 1]
	if {[catch {
	    db_dml update_bounce_info "insert into bulkmail_bounces (bulkmail_id, user_id) values ($bulkmail_id, $user_id)"
	} errmsg] } {
	    ns_log Notice "Error on bulkmail_bounce insert.  key_code: $key_code\ndetails: $details\n$errmsg"
	} else {
	    ns_unlink -nocomplain "$file"
	    incr n_bounces

	}
    }

    if { $n_bounces > 0 } {
	set rows_affected [db_dml handle_bounces "declare
	counter number;
	uid number;
	cursor BOUNCING_IDS is
	select user_id from bulkmail_bounces where active_p = 't' group by user_id having count(user_id) > 2 ;
	one_row BOUNCING_IDS%ROWTYPE;
	begin 
	--:counter := counter;
	counter := 0;
	for one_row in BOUNCING_IDS
	loop
	uid := one_row.user_id;
	update users set email_bouncing_p = 't' where user_id = uid;
	update bulkmail_bounces set active_p = 'f' where user_id = uid;
	commit;
	counter := counter + 1;
	end loop;
	:counter := counter;
	end;
	"]
	ns_log Notice "bulkmail bounce sweeper found $rows_affected bouncing ids."
    }

    db_release_unused_handles 
    ns_log Notice "Done sweeping bounce queue"
}
    

if { [ad_parameter BulkmailActiveP bulkmail] == 1 } {

    # start up the db_flush_wait proc
    ns_thread begindetached "bulkmail_db_flush_wait"
    ns_schedule_daily -thread 3 30 bulkmail_sweep_bounce_queue

}


