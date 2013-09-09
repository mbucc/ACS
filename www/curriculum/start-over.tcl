# /www/curriculum/start-over.tcl

ad_page_contract {
    erases curriculum history cookie and also deletes from database

    @author philg@mit.edu 
    @creation-date October 7, 1999
    @cvs-id start-over.tcl,v 3.2.2.4 2000/07/21 03:59:13 ron Exp
} {}

set user_id [ad_verify_and_get_user_id]

if { $user_id != 0 } {
     
    db_dml cleanup_curric_map "delete from user_curriculum_map where user_id = :user_id"
    db_release_unused_handles
}

# write the "start" cookie
ns_set put [ns_conn outputheaders] "Set-Cookie" "CurriculumProgress=[curriculum_progress_cookie_value]; path=/; expires=Fri, 01-Jan-2010 01:00:00 GMT"

ad_returnredirect "index"
