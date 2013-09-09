# /www/admin/glossary/term-delete.tcl

ad_page_contract {
    drops the specified row from glossary table

    @author Walter McGinnis (walter@arsdigita.com)
    @cvs-id: term-delete.tcl,v 3.2.2.5 2000/07/25 23:47:38 david Exp
    @param term The term to delete.
} {
    {term:notnull,trim} 
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set user_id [ad_maybe_redirect_for_registration]

db_dml deleteterm "delete from glossary 
where term = :term"


db_release_unused_handles

ad_returnredirect "index"
