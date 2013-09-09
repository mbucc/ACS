# /www/register/logout.tcl

ad_page_contract {
    Logs a user out

    @cvs-id logout.tcl,v 3.3.8.4 2000/07/21 04:03:56 ron Exp

} {
    
}

ad_user_logout 
db_release_unused_handles

ad_returnredirect "/"

