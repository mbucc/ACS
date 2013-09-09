#
# tcl/bulkmail-defs.tcl
#

ad_library {
    
  Definitions for bulkmail multithreaded mail sending module
  
    @author gregh@arsdigita.com 
    @cvs-id bulkmail-defs.tcl,v 3.2.2.1 2000/07/21 08:17:52 hqm Exp
}



proc bulkmail_default_mailerthreads {} {
    return 50
}

proc bulkmail_default_smtpport {} {
    # Get the default smtp port (ripped from ns_sendmail)
    set smtpport [ns_config ns/parameters smtpport]
    if [string match "" $smtpport] {
	set smtpport 25
    }
}

proc bulkmail_default_bulkmailhost {} {

    # Get the default smarthost (ripped from ns_sendmail)
    set smtp [ns_config ns/parameters smtphost]
    if [string match "" $smtp] {
	set smtp [ns_config ns/parameters mailhost]
    }
    if [string match "" $smtp] {
	set smtp localhost
    }

    set smtpport [bulkmail_default_smtpport]

    return "$smtp:$smtpport"
}

proc bulkmail_default_queue_threshold {} {
    return 50
}

proc bulkmail_default_acceptable_message_lossage {} {
    return 5
}

proc bulkmail_default_acceptable_host_failures {} {
    return 2
}

proc bulkmail_default_bounce_threshold {} {
    return 3
}

proc bulkmail_max_mailerthreads {} {
    return [ad_parameter MailerThreads bulkmail [bulkmail_default_mailerthreads]]
}

proc bulkmail_parse_host {host} {
    set parsed_host [split $host ":"]

    # If length is 1, we didn't have an attached port.  Default to 25.
    if { [llength $parsed_host] == 1 } {
	lappend parsed_host ":" [bulkmail_default_smtpport]
    }

    return $parsed_host
}
    

proc bulkmail_get_hostlist {} {
    set hostlist [list]
    set host_params [ad_parameter_all_values_as_list BulkmailHost bulkmail]

    if { [llength $host_params] == 0 } {
	set host_params [bulkmail_default_bulkmailhost]
    }

    foreach host $host_params {
	lappend hostlist [bulkmail_parse_host $host]
    }

    return $hostlist
}

proc bulkmail_smtp_hostname {mailhost} {
    return [lindex $mailhost 0]
}

proc bulkmail_smtp_port {mailhost} {
    return [lindex $mailhost 1]
}

proc bulkmail_queue_threshold {} {
    return [ad_parameter BulkmailQueueThreshhold bulkmail [bulkmail_default_queue_threshold]]
}

proc bulkmail_acceptable_message_lossage {} {
    return [ad_parameter BulkmailAcceptableMessageLossage bulkmail [bulkmail_default_acceptable_message_lossage]]
}

proc bulkmail_acceptable_host_failures {} {
    return [ad_parameter BulkmailAcceptableHostFailures bulkmail [bulkmail_default_acceptable_host_failures]]
}

proc bulkmail_bounce_threshold {} {
    return [ad_parameter BulkmailBounceThreshold bulkmail [bulkmail_default_bounce_threshold]]
}

proc bulkmail_bounce_dir {} {
    return [ad_parameter BulkmailBounceDir bulkmail]
#    return "/web/gregh-dev/mail/bounce"
}

proc bulkmail_message_bulkmail_id { message } {
    return [lindex $message 0]
}

proc bulkmail_message_user_id { message } {
    return [lindex $message 1]
}

proc bulkmail_message_sender { message } {
    return [lindex $message 2]
}

proc bulkmail_message_from { message } {
    return [lindex $message 3]
}

proc bulkmail_message_tolist { message } {
    return [lindex $message 4]
}

proc bulkmail_message_bcclist { message } {
    return [lindex $message 5]
}

proc bulkmail_message_body { message } {
    return [lindex $message 6]
}

proc bulkmail_reply_address { key_code } {
    return "[subst [ad_parameter BulkmailReplyAddress bulkmail]]"
}

proc bulkmail_sender_address { key_code } {
    return "[subst [ad_parameter BulkmailSenderAddress bulkmail]]"
}

if { [ad_parameter BulkmailActiveP bulkmail] == 1 } {

    # Set of all of the active instances.  The key is the bulkmail_id, the
    # value is the description passed to bulkmail_begin.
    ns_share -init { set bulkmail_instances [ns_set create -persist bulkmail_instances] } bulkmail_instances

    # Set of the instances that have completed (bulkmail_end completed.)
    # key is the bulkmail_id, and the value is the number of messages sent.
    ns_share -init { set bulkmail_finished_instances [ns_set create -persist bulkmail_finished_instances] } bulkmail_finished_instances

    # This is the initial mail queue.  This will be repeatedly reset as
    # mailer threads are spawned to send mail.
    ns_share -init { set bulkmail_message_queue [list] } bulkmail_message_queue 
    
    # List of the hosts we can use to send mail through.
    ns_share -init { set bulkmail_hosts [bulkmail_get_hostlist] } bulkmail_hosts

    # Set of bulkmail hosts that have failed. key is the hostname, value is
    # the number of failures
    ns_share -init { set bulkmail_failed_hosts [ns_set create -persist bulkmail_failed_hosts] } bulkmail_failed_hosts

    # The index of of bulkmail_hosts to use as the current host
    ns_share -init { set bulkmail_current_host 0 } bulkmail_current_host

    # Set of mutexes used to control access to message counts on individual
    # instances.
    ns_share -init { set bulkmail_instance_mutexes [ns_set create -persist bulkmail_instance_mutexes] } bulkmail_instance_mutexes

    # Share the db_flush_queue
    ns_share -init { set bulkmail_db_flush_queue [list] } bulkmail_db_flush_queue

    # Share the count of threads spawned
    ns_share -init { set bulkmail_threads_spawned 0 } bulkmail_threads_spawned

    # Share the count of threads completed
    ns_share -init { set bulkmail_threads_completed 0 } bulkmail_threads_completed

    # Share the semaphore we use to track our threadcount
    ns_share -init { set bulkmail_threads_sema [ns_sema create [bulkmail_max_mailerthreads]] } bulkmail_threads_sema

    # Share the mutex we use for access to the instances ns_set
    ns_share -init { set bulkmail_instances_mutex [ns_mutex create] } bulkmail_instances_mutex

    # Share the mutex used to share bulkmail_hosts
    ns_share -init { set bulkmail_hosts_mutex [ns_mutex create] } bulkmail_hosts_mutex

    # Share the mutex we use for access to the instance mutexes ns_set
    ns_share -init { set bulkmail_instance_mutexes_mutex [ns_mutex create] } bulkmail_instance_mutexes_mutex

    # Share the mutex we use for access to the finished instances ns_set
    ns_share -init { set bulkmail_finished_instances_mutex [ns_mutex create] } bulkmail_finished_instances_mutex

    # Share the mutex we use for access to the db flush queue
    ns_share -init { set bulkmail_db_flush_queue_mutex [ns_mutex create] } bulkmail_db_flush_queue_mutex

    # Share the mutex we use for access to the spawned count
    ns_share -init { set bulkmail_threads_spawned_mutex [ns_mutex create] } bulkmail_threads_spawned_mutex

    # Share the mutex we use for access to the completed thread count
    ns_share -init { set bulkmail_threads_completed_mutex [ns_mutex create] } bulkmail_threads_completed_mutex

    # Share the mutex we use for access to the message queue
    ns_share -init { set bulkmail_message_queue_mutex [ns_mutex create] } bulkmail_message_queue_mutex

    # Share the mutex for handling the current host index
    ns_share -init {set bulkmail_current_host_mutex [ns_mutex create] } bulkmail_current_host_mutex

    # the mutex for handling failed hosts
    ns_share -init { set bulkmail_failed_hosts_mutex [ns_mutex create] } bulkmail_failed_hosts_mutex

    # Share the mutex and event for the db_flush_wait stuff
    ns_share -init { set bulkmail_db_flush_wait_event_mutex [ns_mutex create] } bulkmail_db_flush_wait_event_mutex

    ns_share -init { set bulkmail_db_flush_wait_event [ns_event create] } bulkmail_db_flush_wait_event

    ns_share -init { set bulkmail_instance_finished_event_mutex [ns_mutex create] } bulkmail_instance_finished_event_mutex

    ns_share -init { set bulkmail_instance_finished_event [ns_event create] } bulkmail_instance_finished_event

}


