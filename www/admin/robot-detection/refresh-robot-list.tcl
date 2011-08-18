# $Id: refresh-robot-list.tcl,v 3.0.4.1 2000/04/28 15:09:20 carsten Exp $
#
# refresh-robot-list.tcl
#
# Created by michael@yoon.org, 05/27/1999
#

set db [ns_db gethandle]

if [catch { ad_replicate_web_robots_db $db } errmsg] {
    ad_return_error "Database Error" $errmsg
    return
}

ad_returnredirect "index.tcl"
