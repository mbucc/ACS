# $Id: flush-memoized-statement.tcl,v 1.1 2000/03/07 16:49:38 jsalz Exp $
# Name:        flush-memoized-statement.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        29 Feb 2000
# Description: Performs util_memoize_flush_local on the statement parameter.
# Inputs:      statement

if { ![server_cluster_authorized_p [ns_conn peeraddr]] } {
    ns_returnforbidden
    return
}

util_memoize_flush_local [ns_queryget statement]

if { [server_cluster_logging_p] } {
    ns_log "Notice" "Distributed flush of [ns_queryget statement]"
}
ns_return 200 "text/plain" "Successful."
