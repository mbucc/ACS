# $Id: adhref.tcl,v 3.0.4.1 2000/04/28 15:09:39 carsten Exp $
# adimg.tcl
#
# at this point mostly by philg@mit.edu 
# last edited November 24, 1999 to address a concurrency problem 
# 
# this page 
#   finds the target URL that corresponds to the banner we displayed
#   sends bytes back to the browser instructing the browser to redirect to that URL
#   closes the TCP connection to the user
#   while this thread is still alive, logs the clickthrough 
#   (optionally this page will not log the clickthrough, e.g., 
#    if this is invoked from the /admin directory)

set_the_usual_form_variables 0

# adv_key, maybe suppress_logging_p

if { ![info exists adv_key] || $adv_key==""} {
    ad_returnredirect [ad_parameter DefaultTargetUrl adserver "/"]
    return
}

set db [ns_db gethandle]

set target_url [database_to_tcl_string_or_null $db "select target_url 
from advs
where adv_key = '$QQadv_key'"]

if { $target_url == "" } {
    ad_returnredirect [ad_parameter DefaultTargetUrl adserver "/"]
    return
} 

ad_returnredirect $target_url

if { [info exists suppress_logging_p] && $suppress_logging_p == 1 } {
    return
}

ns_conn close

# we've returned to the user but let's keep this thread alive to log

set update_sql "update adv_log 
set click_count = click_count + 1 
where adv_key = '$QQadv_key'
and entry_date = trunc(sysdate)"

ns_db dml $db $update_sql

set n_rows [ns_ora resultrows $db]

if { $n_rows == 0 } {
    # there wasn't already a row there
    # let's be careful in case another thread is executing concurrently
    # on the 10000:1 chance that it is, we might lose an update but 
    # we won't generate an error in the error log and set off all the server
    # monitor alarms
    set insert_sql "insert into adv_log
(adv_key, entry_date, click_count)
select '$QQadv_key', trunc(sysdate), 1 
from dual
where 0 = (select count(*) 
           from adv_log
           where adv_key='$QQadv_key'
           and entry_date = trunc(sysdate))"
    ns_db dml $db $insert_sql
}

if [ad_parameter DetailedPerUserLoggingP adserver 0] {
    set user_id [ad_get_user_id]
    if { $user_id != 0 } {
	# we know who this user is
	ns_db dml $db "insert into adv_user_map
(user_id, adv_key, event_time, event_type)
values 
($user_id, '$QQadv_key', sysdate, 'c')"
    }
}
