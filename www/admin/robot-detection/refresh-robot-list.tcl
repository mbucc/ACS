# www/admin/robot-detection/refresh-robot-list.tcl

ad_page_contract {
    @author Michael Yoon (michael@yoon.org)
    @creation-date 05-MAY-1999
    @cvs-id refresh-robot-list.tcl,v 3.1.6.3 2000/07/21 03:57:58 ron Exp
} {
}

if [catch { ad_replicate_web_robots_db } errmsg] {
    ad_return_error "Database Error" $errmsg
    return
}

ad_returnredirect "index.tcl"
