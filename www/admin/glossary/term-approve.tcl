# /www/admin/glossary/term-approve.tcl

ad_page_contract {
    update row by setting approved_p to 't'
    
    @author unknown modified by walter@arsdigita.com, 2000-07-03
    @cvs-id term-approve.tcl,v 3.2.2.5 2000/07/25 23:47:38 david Exp
    @param term The term to define
} {
    {term:notnull,trim}
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]


set sql "update glossary 
set approved_p = 't'
where term = :term"
 
db_dml update_term $sql

db_release_unused_handles

ad_returnredirect "index"
