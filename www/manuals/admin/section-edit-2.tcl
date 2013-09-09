# /www/admin/manuals/section-edit-2.tcl
ad_page_contract {
    Program to modify characteristics of a section 

    @param manual_id the ID of the manual the section belongs to
    @param section_id the ID of the section
    @param section_title the title of the section
    @param label a string for referencing the section

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id section-edit-2.tcl,v 1.4.2.4 2000/07/21 04:02:55 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
    section_title:trim,notnull
    {label ""}
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

set label_used_id [db_string used_label "
select section_id from manual_sections
where label = :label" -default ""]

page_validation {
    if {![empty_string_p $label_used_id] && $label_used_id != $section_id} {
	error "The label $label is already in use.\n"
    }
}

db_dml section_update "
update manual_sections
set    section_title = :section_title,
       label         = :label
where  section_id = :section_id"

ad_returnredirect manual-view.tcl?manual_id=$manual_id
return


