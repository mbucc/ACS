# $Id: watchdog-defs.tcl,v 3.1 2000/02/26 12:55:30 jsalz Exp $


# A complete rewrite of Watchdog
#
# dvr@arsdigita.com, Nov 28, 1999
#
# This package provides a page that prints all errors from
# the system log. (/admin/errors).
#
# If you add a section to your ini file like:
#
#    [ns/server/yourservicename/acs/monitoring]
#    WatchDogFrequency=15
#  
# then watchdog will check the error log every 15 minutes
# and sent any error messages to ad_system_owner.

proc wd_errors {{num_minutes ""} {num_bytes ""}} {

    if ![empty_string_p $num_bytes] {
        append options "-${num_bytes}b "
    }
    if ![empty_string_p $num_minutes] {
        append options "-${num_minutes}m "
    }

    set command [ad_parameter WatchDogParser monitoring]
    
    if { ![file exists $command] } {
	ns_log Notice "watchdog(wd_errors): Can't find WatchDogParser: $command doesn't exist" 
    } else {
	set error_log [ns_info log]
	if [info exists options] {
	    return [exec $command $options $error_log]
	} else {
	    return [exec $command $error_log]    
	}
    }
}


proc wd_email_frequency {} {
    # in minutes
    return [ad_parameter WatchDogFrequency monitoring 15]
}

proc wd_people_to_notify {} {

    set people_to_notify [ad_parameter_all_values_as_list PersontoNotify monitoring]
    if [empty_string_p $people_to_notify] {
        return [ad_system_owner]
    } else {
        return $people_to_notify
    }
}

proc wd_mail_errors {} {
    set num_minutes [wd_email_frequency]   

    ns_log Notice "Looking for errors..."

    set system_owner [ad_system_owner]
    
    set errors [wd_errors $num_minutes]

    if {[string length $errors] > 50} {
        ns_log Notice "Errors found"
        foreach person [wd_people_to_notify] {
            ns_log Notice "Sending email to $person..."
            ns_sendmail $person $system_owner "Errors on [ad_system_name]" $errors
        }
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
