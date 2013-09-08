# /www/adserver/adhref.tcl

ad_page_contract {

    this page finds the target URL that corresponds to the banner we displayed
    sends bytes back to the browser instructing the browser to redirect to that URL
    closes the TCP connection to the user
    while this thread is still alive, logs the clickthrough 
    (optionally this page will not log the clickthrough, e.g., 
    if this is invoked from the /admin directory)

    @author philg@mit.edu
    @creation-date 11/24/1999
    @cvs-id adhref.tcl,v 3.1.6.2 2000/07/22 20:50:37 berkeley Exp
} {
    adv_key
    suppress_logging_p:optional  
}

# last edited November 24, 1999 to address a concurrency problem 

if { ![info exists adv_key] || $adv_key==""} {
    ad_returnredirect [ad_parameter DefaultTargetUrl adserver "/"]
    return
}



set target_url [db_string adv_url_query "
select target_url 
from advs 
where adv_key = :adv_key" -default ""]

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
where adv_key = :adv_key 
and entry_date = trunc (sysdate)"

db_dml adv_update_query $update_sql

set n_rows [db_resultrows]

if { $n_rows == 0 } {
    # there wasn't already a row there
    # let's be careful in case another thread is executing concurrently
    # on the 10000:1 chance that it is, we might lose an update but 
    # we won't generate an error in the error log and set off all the server
    # monitor alarms
    set insert_sql "insert into adv_log
    (adv_key, entry_date, click_count)
    select :adv_key, trunc (sysdate), 1 
    from dual 
    where 0 = (select count (*) 
               from adv_log 
               where adv_key = :adv_key 
               and entry_date = trunc (sysdate))"
    db_dml adv_insert $insert_sql
}

if [ad_parameter DetailedPerUserLoggingP adserver 0] {
    set user_id [ad_get_user_id]
    if { $user_id != 0 } {
	# we know who this user is
	db_dml adv_known_user_insert "
	insert into adv_user_map 
        (user_id, adv_key, event_time, event_type) 
	values 
	(:user_id, :adv_key, sysdate, 'c')"
    }
}










