# /tcl/ad-monitor.tcl

ad_library {

Internal error monitors, beyond the static files in /SYSTEM that
external monitors such as Uptime use.

The overall goal here is that the ad_host_administrator gets notified
if something is horribly wrong, but not more than once every 15
minutes.

We store the last [ns_time] (seconds since 1970) notification time in
ad_host_administrator_last_notified

    @creation-date 6 Nov 1998
    @author philg@mit.edu
    @cvs-id ad-monitor.tcl,v 3.0.14.2 2000/07/25 11:27:48 ron Exp
}

ns_share -init { set ad_host_administrator_last_notified 0 } ad_host_administrator_last_notified

proc ad_notify_host_administrator {subject body {log_p 0}} {
    ns_share ad_host_administrator_last_notified
    if $log_p {
	# usually the error will be in the error log anyway
	ns_log Notice "ad_notify_host_administrator: $subject\n\n$body\n\n"
    }
    if { [ns_time] > [expr $ad_host_administrator_last_notified + 900] } {
	# more than 15 minutes have elapsed since last note
	set ad_host_administrator_last_notified [ns_time]
	if [catch { ns_sendmail [ad_host_administrator] [ad_system_owner] $subject $body } errmsg] {
	    ns_log Error "failed sending email note to [ad_host_administrator]"
	}
    }
}
