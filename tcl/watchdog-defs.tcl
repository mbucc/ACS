ad_library {

     A complete rewrite of Watchdog
    
     This package provides a page that prints all errors from
     the system log. (/admin/errors).
    
     If you add a section to your ini file like:
    
        [ns/server/yourservicename/acs/monitoring]
        WatchDogFrequency=15
      
     then watchdog will check the error log every 15 minutes
     and sent any error messages to ad_system_owner.

    @author
    @creation-date Nov 28, 1999
    @cvs-id watchdog-defs.tcl,v 3.9.2.4 2000/07/31 00:44:59 lars Exp
}

ad_proc wd_errors {{num_minutes ""} {num_bytes "200000"}} "" {

    set options ""
    if ![empty_string_p $num_minutes] {
	validate_integer "Minutes" "$num_minutes"
        set options "-${num_minutes}m "
    } else {
	validate_integer "Bytes" "$num_bytes"
        set options "-${num_bytes}b "
    }

    set command [ad_parameter WatchDogParser monitoring]

    if { ![file exists $command] } {
	ns_log Notice "watchdog(wd_errors): Can't find WatchDogParser: $command doesn't exist" 
    } else {
	# This has been changed from the previous version's concat
	# because it did not work.  Some quick testing
	# did not reveal an elegant solution, so we're going back
	# to the old less-elegant-but-functional solution
	if { [catch { set result [exec $command $options [ns_info log]] } err_msg] } {
	    ns_log error "Watchdog(wd_errors): $err_msg"
	    return ""
	} else {
	    return $result
	}
    }
}

ad_proc wd_email_frequency {} "" {
    # in minutes
    return [ad_parameter WatchDogFrequency monitoring 15]
}

ad_proc wd_people_to_notify {} "" {

    set people_to_notify [ad_parameter_all_values_as_list PersontoNotify monitoring]
    if [empty_string_p $people_to_notify] {
        return [ad_system_owner]
    } else {
        return $people_to_notify
    }
}

ad_proc wd_mail_errors {} "" {

    set num_minutes [wd_email_frequency]   

    ns_log Notice "Looking for errors..."

    set errors [wd_errors $num_minutes]

    if {[string length $errors] > 50} {
        ns_log Notice "Errors found"
	# Let's put the url to this server in the email message
	# to make it crystal clear which server is having problems
	set message "
([ad_parameter SystemURL])

$errors"
        wd_email_notify_list "Errors on [ad_system_name]" $message
    }
}

ns_share -init {set wd_installed_p 0} wd_installed_p

if {! $wd_installed_p} {
    set check_frequency [wd_email_frequency]
    if {$check_frequency > 0} {
        ad_schedule_proc [expr 60 * $check_frequency] wd_mail_errors
        ns_log Notice "Scheduling watchdog"
    }
    set wd_installed_p 1
}

ad_proc wd_email_notify_list { subject message } {
    Sends the specified subject and message in an email to all people on the notify list.
} {
    set system_owner [ad_system_owner]
    foreach person [wd_people_to_notify] {
	ns_sendmail $person $system_owner $subject $message
    }
}



