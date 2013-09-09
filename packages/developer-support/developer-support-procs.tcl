# developer-support-procs.tcl,v 1.5.2.3 2000/07/14 04:51:41 jsalz Exp
# File:        developer-support-procs.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        22 Apr 2000
# Description: Provides routines used to aggregate request/response information for debugging.

proc_doc ds_enabled_p {} { Returns true if developer-support facilities are enabled. } {
    if { [catch { set enabled_p [nsv_get ds_properties enabled_p] }] } {
	return 0
    }
    return $enabled_p
}

proc_doc ds_database_enabled_p {} { Returns true if developer-support database facilities are enabled. } {
    return [ad_parameter "DatabaseEnabledP" "developer-support" 0]
}

proc_doc ds_collection_enabled_p {} { Returns true if developer-support information collection is enabled for this connection. } {
    global ad_conn
    if { ![ds_enabled_p] || ![info exists ad_conn(request)] } {
	return 0
    }
    foreach pattern [nsv_get ds_properties enabled_ips] {
	if { [string match $pattern [ns_conn peeraddr]] } {
	    return 1
	}
    }
    return 0
}

proc_doc ds_lookup_administrator_p { user_id } { Used with util_memoize to cache the results of ad_administrator_p. } {
    set value [ad_administrator_p $user_id]
    return $value
}

proc_doc ds_link {} { Returns the "Developer Information" link in a right-aligned table, if enabled. } {
    global ad_conn
    if { [ds_collection_enabled_p] && \
	    [util_memoize [list ds_lookup_administrator_p [ad_get_user_id]]] } {
	set out "
<table align=right cellspacing=0 cellpadding=0><tr><td align=right>
<a href=\"/admin/developer-support/request-info?request=$ad_conn(request)\">Developer Information</a>
</td></tr>
"

        if { [catch { nsv_exists ds_request . }] } {
	    ns_log "Warning" "ds_request NSVs not initialized"
	    return
	}

        if { [nsv_exists ds_request "$ad_conn(request).db"] } {
	    set total 0
	    set counter 0
	    foreach { handle command statement_name sql start end errno error } [nsv_get ds_request "$ad_conn(request).db"] {
		incr total [expr { $end - $start }]
		if { [lsearch { dml exec 1row 0or1row select } [lindex $command 0]] >= 0 } {
		    incr counter
		}
	    }
	    if { $counter > 0 } {
		append out "<tr><td align=right>$counter database command[ad_decode $counter 1 " taking" "s totalling"] [format "%.f" [expr { $total / 1000 }]] ms</td></tr>"
	    }
	}

	if { [nsv_exists ds_request "$ad_conn(request).conn"] } {
	    array set conn [nsv_get ds_request "$ad_conn(request).conn"]
	    if { [info exists conn(startclicks)] } {
		append out "<tr><td align=right>page served in
[format "%.f" [expr { ([clock clicks] - $conn(startclicks)) / 1000 }]] ms</td></tr>\n"
	    }
	}

        if { [nsv_exists ds_request "$ad_conn(request).comment"] } {
	    append out "<tr><td><br>"
	    foreach comment [nsv_get ds_request "$ad_conn(request).comment"] {
		append out "<b>Comment:</b> $comment<br>\n"
	    }
	    append out "</td></tr>"
	}
	
	append out "</table>\n"
	return $out
    }
    return ""
}

proc_doc ds_collect_connection_info {} { Collects information about the current connection. Should be called only at the very beginning of the request processor handler. } {
    if { [ds_enabled_p] } {
	ds_add start [ns_time]
	ds_add conn startclicks [clock clicks]
	for { set i 0 } { $i < [ns_set size [ns_conn headers]] } { incr i } {
	    ds_add headers [ns_set key [ns_conn headers] $i] [ns_set value [ns_conn headers] $i]
	}
	foreach param { method url query request peeraddr } {
	    ds_add conn $param [ns_conn $param]
	}
    }
}    

proc_doc ds_collect_db_call { db command statement_name sql start_time errno error } {
    if { [ds_collection_enabled_p] && [ds_database_enabled_p] } {
	ds_add db $db $command $statement_name $sql $start_time [clock clicks] $errno $error
    }
}

proc_doc ds_add { name args } { Sets a developer-support property for the current request. Should never be used except by elements of the request processor (e.g., security filters or abstract URLs). } {
    if { [catch { nsv_exists ds_request . }] } {
	ns_log "Warning" "ds_request NSVs not initialized"
	return
    }

    global ad_conn
    eval [concat [list nsv_lappend ds_request "$ad_conn(request).$name"] $args]
}

proc_doc ds_comment { value } { Adds a comment to the developer-support information for the current request. } {
    ds_add comment $value
}

proc ds_sweep_data {} {
    set now [ns_time]
    set lifetime [ad_parameter DataLifetime "developer-support" 900]

    # kill_requests is an array of request numbers to kill
    array set kill_requests [list]

    set names [nsv_array names ds_request]
    foreach name $names {
	if { [regexp {^([0-9]+)\.start$} $name "" request] && \
		$now - [nsv_get ds_request $name] > $lifetime } {
	    set kill_requests($request) 1
	}
    }
    set kill_count 0
    foreach name $names {
	if { [regexp {^([0-9]+)\.} $name "" request] && \
		[info exists kill_requests($request)] } {
	    incr kill_count
	    nsv_unset ds_request $name
	}
    }	

    ns_log "Notice" "Swept developer support information for [array size kill_requests] requests ($kill_count nsv elements)"
}

proc_doc ds_trace_filter { conn args why } { Adds developer-support information about the end of sessions.} {
    if { [ds_collection_enabled_p] } {
	ds_add conn end [ns_time] endclicks [clock clicks]

	for { set i 0 } { $i < [ns_set size [ns_conn outputheaders]] } { incr i } {
	    ds_add oheaders [ns_set key [ns_conn outputheaders] $i] [ns_set value [ns_conn outputheaders] $i]
	}

	foreach param { browser_id validated session_id user_id } {
	    global ad_sec_$param
	    if { [info exists ad_sec_$param] } {
		ds_add conn $param [set "ad_sec_$param"]
	    }
	}
    }

    return "filter_ok"
}
