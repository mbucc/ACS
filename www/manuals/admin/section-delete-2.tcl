# /www/manuals/admin/section-delete-2.tcl
ad_page_contract {
    Delete a section.

    @param manual_id the ID of the manual
    @param section_id the ID of the section to be deleted

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Mar 2000
    @cvs-id section-delete-2.tcl,v 1.3.2.2 2000/07/21 04:02:53 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
}

# ---------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

db_transaction {

    # First delete any comments about this section.

    db_dml delete_comments "
    delete from general_comments
    where  on_which_table = 'manual_sections'
    and    on_what_id     = :section_id"

    # Now delete the section

    db_dml section_delete "
    delete from manual_sections where section_id = :section_id"
}

ad_returnredirect "manual-view.tcl?manual_id=$manual_id"
