# /www/admin/glossary/term-edit-2.tcl
ad_page_contract {
    executes update to glossary for term
    
    @author unknown modified by walter@arsdigita.com, 2000-07-02
    @cvs-id  term-edit-2.tcl,v 3.2.2.8 2000/11/18 06:13:17 walter Exp
    @param term The term to edit
    @param definition the new definition
} {
    term:notnull,trim
    definition:notnull,trim,html
}

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set sql "update glossary set definition = :definition where term = :term"

db_dml update_term $sql

db_release_unused_handles

ad_returnredirect "one?[export_url_vars term]"