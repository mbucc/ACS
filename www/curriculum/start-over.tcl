# $Id: start-over.tcl,v 3.0.4.1 2000/04/28 15:09:55 carsten Exp $
#
# /curriculum/start-over.tcl
#
# by philg@mit.edu on October 7, 1999
#
# erases curriculum history cookie and also deletes from database
# 

set user_id [ad_verify_and_get_user_id]

if { $user_id != 0 } {
    set db [ns_db gethandle] 
    ns_db dml $db "delete from user_curriculum_map where user_id = $user_id"
    ns_db releasehandle $db
}

# write the "start" cookie
ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=[curriculum_progress_cookie_value]; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"

ad_returnredirect "index.tcl"
