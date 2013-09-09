# /www/admin/manuals/manual-delete-2.tcl
ad_page_contract {
    Nuke all the content associated with a manual

    @param manual_id the ID of the manual being deleted

    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id manual-delete-2.tcl,v 1.5.2.2 2000/07/21 03:57:33 ron Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Need to put in sections for content removal (delete the html files and images)

# Drop data stored in tables

db_transaction {
    db_dml figures_delete "
    delete from manual_figures  where manual_id = :manual_id"
    db_dml sections_delete "
    delete from manual_sections where manual_id = :manual_id"
    db_dml manual_delete "
    delete from manuals         where manual_id = :manual_id"
}

# Done

ad_returnredirect "index.tcl"