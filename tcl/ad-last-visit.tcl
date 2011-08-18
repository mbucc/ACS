# $Id: ad-last-visit.tcl,v 3.1 2000/02/26 12:55:27 jsalz Exp $
# ad-last-visit.tcl, created February 13, 1999 by philg@mit.edu
#  (this is actually a modification of code from cognet.mit.edu,
#   built in summer 1998)

# substantially modified on March 26, 1999 to include session tracking

# teadams - substantially modified on Sept 17 to not overcount non-cookied browsers

# we adhere to the algorithm specified in 
#   http://photo.net/wtr/thebook/community.html 

# this file also handles the maintenance of last_visit and
# second_to_last_visit cookies

# each of these is a number returned by [ns_time] (seconds
# since January 1, 1970).

proc ad_update_last_visits {db user_id} {
    ns_db dml $db "update users
set last_visit = sysdate,
    second_to_last_visit = last_visit,
    n_sessions = n_sessions + 1
where user_id = $user_id"
}


proc ad_update_last_visit {db user_id} {
    ns_db dml $db "update users
set last_visit = sysdate
where user_id = $user_id"
}

proc ad_update_session_statistics {db repeat_p {session_p 1}} {
    if $repeat_p {
	if $session_p {
	    set update_sql "update session_statistics 
set session_count = session_count + 1, 
repeat_count = repeat_count + 1 
where entry_date = trunc(sysdate)"
	    set insert_sql "insert into session_statistics (session_count, repeat_count, entry_date)
	    values
	    (1,1,trunc(sysdate))"
       } else {
	   # The user came to the site with no cookies.
	   # We recorded a session, but no repeat session
	   # at this point.

	   # The user subsequenty logged in.  We now
	   # know that this is a repeat visit.

	    set update_sql "update session_statistics 
set repeat_count = repeat_count + 1 
where entry_date = trunc(sysdate)"
	    set insert_sql "insert into session_statistics (session_count, repeat_count, entry_date)
	    values
	    (0,1,trunc(sysdate))"
       }
   } else {
	# not a repeat user
	set update_sql "update session_statistics 
set session_count = session_count + 1
where entry_date = trunc(sysdate)"
        set insert_sql "insert into session_statistics (session_count, repeat_count, entry_date)
values
(1,0,trunc(sysdate))"
    }
    ns_db dml $db $update_sql
    set n_rows [ns_ora resultrows $db]
    if { $n_rows == 0 } {
	# there wasn't already a row there
	ns_db dml $db $insert_sql
    }
}

# returns the seconds since January 1, 1970 of the second_to_last_visit
# (from the cookie).  If there is no cookie, return ""

proc ad_second_to_last_visit_ut {} {
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    if { [regexp {second_to_last_visit=([^;]+)} $cookie match second_to_last_visit] } {
	return $second_to_last_visit
    } else {
	return ""
    }
}

proc_doc ad_current_hours_difference_from_GMT {} "Looks at ad.ini file to see where server is located and also at last element of ns_localtime to see whether we're on daylight savings time or not" {
    # [lindex [ns_localtime] 8] will be 1 if we're on daylight time, 
    # 0 otherwise
    set daylight_adjustment [lindex [ns_localtime] 8]
    return [expr [ad_parameter HoursDifferenceFromGMT] + $daylight_adjustment]
}

ns_share -init {set ad_last_visits_filters_installed_p 0} ad_last_visits_filters_installed_p

if { [ad_parameter LastVisitCookiesEnabledP "" 1] && !$ad_last_visits_filters_installed_p } {
    # we only establish these filters if the system is enabled in ad.ini
    set ad_last_visits_filters_installed_p 1
    # will maintain the last_visit and second_to_last_visits users columns
    # we could have done just /* but that puts cookies on all the images
    # and so forth; it is unfriendly to people who've linked to images
    # in-line from other pages and it is unfriendly to those who have
    # "warn about cookies" enabled
    ad_register_filter preauth GET /*.html  ad_maintain_last_visits
    ad_register_filter preauth GET /*.htm   ad_maintain_last_visits
    ad_register_filter preauth GET /*.tcl   ad_maintain_last_visits
    ad_register_filter preauth GET /*.adp   ad_maintain_last_visits
    ad_register_filter preauth GET /        ad_maintain_last_visits
}

# we do all the work in a helper procedure so that we can wrap a catch around
# the whole thing (AOLserver 2.3.2 won't serve the page at all if there is a 
# serious error with the filter)

proc ad_maintain_last_visits_internal {} {
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    set user_id [ad_get_user_id] 
    # parse out the last_visit date from the cookie
    if { [regexp {last_visit=([^;]+)} $cookie match last_visit] } {
	# we have a last visit cookie already, but maybe it is old
	# and needs refreshing
	set expiration_seconds [ad_parameter LastVisitExpiration "" 86400]

	if { [ns_time] - $last_visit > $expiration_seconds } {
	    # let's consider this a new visit and update the cookie
	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "last_visit=[ns_time]; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "second_to_last_visit=$last_visit; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    set db [ns_db gethandle -timeout -1]
	    # let's record this as a repeat user
	    ad_update_session_statistics $db 1
	    # if the person is a registered user, update the users table
	    if { $user_id != 0 } {
		ad_update_last_visits $db $user_id
	    }
	    ns_db releasehandle $db
	}
    } else {

	# no last_visit cookie
	ns_share ad_last_visit_ip_cache
	set ip_address [ns_conn peeraddr]
	set ad_ip_last_visit_cache_seconds  [ad_parameter LastVisitCacheUpdateInterval "" 600]

	if {![info exists ad_last_visit_ip_cache($ip_address)] || ([ns_time] - $ad_last_visit_ip_cache($ip_address)) > $ad_ip_last_visit_cache_seconds  } {
	    # we haven't seen this IP, let's consider this a new
	    # sessions
	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "last_visit=[ns_time]; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    set ad_last_visit_ip_cache($ip_address) [ns_time]
	} else {
	    # We've already seen this IP.
	    # Since there is no last visit cookie, we
	    # assume the attempt to cookie was unsuccessful
	    # on a previous hit
	    return
	}

	set db [ns_db gethandle -timeout -1]
	if { [empty_string_p $db] } {
	    return
	}

	# let's record this as a new visit
	if {$user_id == 0} {
	    ad_update_session_statistics $db 0
	} else {
	    # this is the very rare case where the user
	    # has a user_id cooke, but not a last visit cookie
	    # if the person is a user, update the last_visit dates in the database
	    ad_update_session_statistics $db 1
	    ad_update_last_visits $db $user_id
	    # we use an explicit to_char here in case someone is
	    # using an older version of our Oracle driver (which had
	    # a bug in pulling through large numbers)
	    # the hard part of this is turning what Oracle gives us 
	    # (local time) into universal time (GMT)
	    set second_to_last_visit_ut [database_to_tcl_string $db "select to_char(86400*(second_to_last_visit - to_date('1970-01-01') - ([ad_current_hours_difference_from_GMT]/24)),'9999999999')
from users
where user_id = $user_id"]
            if ![empty_string_p $second_to_last_visit_ut] {
		ns_set put [ns_conn outputheaders] "Set-Cookie" "second_to_last_visit=$second_to_last_visit_ut; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    }
	}
	ns_db releasehandle $db
    }
}


# Same as above, but updates last_visit more frequently, in order to support
# querying for who's online.

# Think of last_visit as representing the actual time of the last
# visit (with some delay controlled by LastVisitExpiration, for
# efficiency) and second_to_last_visit as representing the last visit
# time for the previous "session".

proc ad_maintain_last_visits_for_whosonline_internal {} {
    
    set headers [ns_conn headers]
    set cookie [ns_set get $headers Cookie]
    set user_id [ad_get_user_id] 

    # Parse out the last_visit value from the cookie.
    if { ![regexp {last_visit=([^;]+)} $cookie match last_visit] } {
	set last_visit ""
    }
  
    if { ![regexp {second_to_last_visit=([^;]+)} $cookie match second_to_last_visit] } {
	set second_to_last_visit ""
    }
    
    #ns_log Notice "ad_maintain_last_visits_internal working on user_id #$user_id whose cookie is \"$cookie\".  We've got a last_visit of \"$last_visit\" and a second_to_last_visit of \"$second_to_last_visit\"."

    set now [ns_time]
    set expiration_seconds [ad_parameter LastVisitExpiration "" 86400]
    set update_seconds [ad_parameter LastVisitUpdateInterval "" 600]
    set ad_ip_last_visit_cache_seconds  [ad_parameter LastVisitCacheUpdateInterval "" 600]

    if { ![empty_string_p $last_visit] } {
	if { ($now - $last_visit > $expiration_seconds) || \
             (![empty_string_p $second_to_last_visit] && (($now - $second_to_last_visit) > 4 * $expiration_seconds)) } {
	    # The last visit was long enough ago to consider
	    # this a new session OR the second to last visit was way old (four times as long as expiration)

	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "last_visit=$now; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "second_to_last_visit=$last_visit; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"

	    set db [ns_db gethandle -timeout -1]
	    if { ![empty_string_p $db] } {
		# let's record this as a repeat user
		ad_update_session_statistics $db 1

		# if the person is a registered user, update the users table
		if {$user_id != 0} {
		    ad_update_last_visits $db $user_id
		}
		
		ns_db releasehandle $db
	    }
	} elseif { $now - $last_visit > $update_seconds } {
	    # This counts as the same session; just update the last_visit
	    # cookie and database field.
	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "last_visit=$now; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    set db [ns_db gethandle -timeout -1]
	    if { ![empty_string_p $db] } {
		# if the person is a registered user, update the users table
		if {$user_id != 0} {
		    ad_update_last_visit $db $user_id
		}
		
		ns_db releasehandle $db
	    }
	}
	# last visit was too recent to do anything about, don't do anything
    } else {
	# no last_visit cookie

	ns_share ad_last_visit_ip_cache
	set ip_address [ns_conn peeraddr]

	if {![info exists ad_last_visit_ip_cache($ip_address)] || ([ns_time] - $ad_last_visit_ip_cache($ip_address)) > $ad_ip_last_visit_cache_seconds  } {
	    # we haven't seen this IP, let's consider this a new
	    # session
	    ns_set put [ns_conn outputheaders]  "Set-Cookie" "last_visit=[ns_time]; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    set ad_last_visit_ip_cache($ip_address) [ns_time]
	    set db [ns_db gethandle -timeout -1]
	    if { [empty_string_p $db] } {
		return
	    }
	} else {
	    # We've already seen this IP.
	    # Since there is no last visit cookie, we
	    # assume the attempt to cookie was unsuccessful
	    # on a previous hit

	    return
	}

	if {$user_id == 0} {
	    ad_update_session_statistics $db 0
	} else {
	    # this is the rare case where the user has a user_id
	    # cookie, but not a last visit cookie
	    ad_update_session_statistics $db 1
	    # let's record this as a new user
	    # if the person is a user, update the last_visit dates in the database
	    ad_update_last_visits $db $user_id
	    # we use an explicit to_char here in case someone is
	    # using an older version of our Oracle driver (which had
	    # a bug in pulling through large numbers)
	    # the hard part of this is turning what Oracle gives us 
	    # (local time) into universal time (GMT)
	    set second_to_last_visit_ut [database_to_tcl_string $db "select to_char(86400*(second_to_last_visit - to_date('1970-01-01') - ([ad_current_hours_difference_from_GMT]/24)),'9999999999')
from users
where user_id = $user_id"]
            if ![empty_string_p $second_to_last_visit_ut] {
		ns_set put [ns_conn outputheaders] "Set-Cookie" "second_to_last_visit=$second_to_last_visit_ut; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"
	    }
	}
	ns_db releasehandle $db
    }
}

proc ad_maintain_last_visits {conn args why} {
    set useragent [ns_set get [ns_conn headers] "User-Agent"]
    if { [string match *aolserver* [string tolower $useragent]] } {
	return filter_ok
    }
    if [catch {
	if { [ad_parameter WhosOnlineP "" 0] } {
	    ad_maintain_last_visits_for_whosonline_internal
	} else {
	    ad_maintain_last_visits_internal
	}
    } errmsg] {
	ns_log Error "ad_maintain_last_visits filter got an error:  $errmsg"
    }
    return filter_ok
}


