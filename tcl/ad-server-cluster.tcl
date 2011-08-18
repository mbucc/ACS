# $Id: ad-server-cluster.tcl,v 3.1 2000/03/07 16:49:18 jsalz Exp $
# File:        ad-server-cluster.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        7 Mar 2000
# Description: Provides methods for communicating between load-balanced servers.

util_report_library_entry

proc_doc server_cluster_enabled_p {} { Returns true if clustering is enabled. } {
    return [ad_parameter ClusterEnabledP server-cluster 0]
}

proc_doc server_cluster_all_hosts {} { Returns a list of all hosts, possibly including this host, in the server cluster. } {
    if { ![server_cluster_enabled_p] } {
	return [list]
    }
    return [ad_parameter_all_values_as_list ClusterPeerIP server-cluster]
}

proc_doc server_cluster_peer_hosts {} { Returns a list of all hosts, excluding this host, in the server cluster. } {
    set peer_hosts [list]
    set my_ip [ns_config ns/server/[ns_info server]/module/nssock Address]

    foreach host [server_cluster_all_hosts] {
	if { $host != $my_ip } {
	    lappend peer_hosts $host
	}
    }

    return $peer_hosts
}

proc_doc server_cluster_authorized_p { ip } { Can a request coming from $ip be a valid cluster request, i.e., matches some value in ClusterIPMask or is 127.0.0.1? } {
    if { ![server_cluster_enabled_p] } {
	return 0
    }

    if { $ip == "127.0.0.1" } {
	return 1
    }
    # lsearch -glob appears to crash AOLserver 2. Oh well.
    foreach glob [ad_parameter_all_values_as_list ClusterAuthorizedIP server-cluster] {
	if { [string match $glob $ip] } {
	    return 1
	}
    }
    return 0
}

proc server_cluster_do_httpget { url timeout } {
    if { [catch {
	set page [ns_httpget $url $timeout 0]
	if { ![regexp -nocase successful $page] } {
	    ns_log "Error" "Clustering: ns_httpget $url returned unexpected value. Is /SYSTEM/flush-memoized-statement.tcl set up on this host?"
	}
    } error] } {
	ns_log "Error" "Clustering: Unable to ns_httpget $url (with timeout $timeout): $error"
    }
}

proc_doc server_cluster_logging_p {} { Returns true if we're logging cluster requests. } {
    return [ad_parameter EnableLoggingP server-cluster 0]
}

ad_proc server_cluster_httpget_from_peers {
    { -timeout 5 }
    url
} { Schedules an HTTP GET request to be issued immediately to all peer hosts (using ad_schedule_proc -once t -thread t -debug t 0). } {
    if { ![string match /* $url] } {
	set url "/$url"
    }
    foreach host [server_cluster_peer_hosts] {
	# Schedule the request. Don't actually issue the request in this thread, since
	# (a) we want to parallelize the requests, and (b) we want this procedure to
	# return immediately.
	ad_schedule_proc -once t -thread t -debug t 0 server_cluster_do_httpget "http://$host$url" $timeout
    }
}

util_report_successful_library_load
