# /www/manual/admin/section-delete.tcl
ad_page_contract {
    Confirmation page for deleting a section

    @param manual_id the ID of the manual containing this section
    @param section_id the ID of the section to be deleted

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id section-delete.tcl,v 1.4.2.2 2000/07/21 04:02:54 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# Get the information for this section

set name [db_string section_title "
select section_title from manual_sections where section_id = :section_id"]

set title [db_string manual_title "
select title from manuals where manual_id = :manual_id"]

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_set_property title "Delete Section: \"$name\""
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index" "Admin"] \
	[list "manual-view?manual_id=$manual_id" $title] \
	"Delete Section"]

doc_body_append "

<p> Are you sure you want to completely delete the section \"$name\:
from the database?  This operation is not reversible.</p>

<form action=section-delete-2 method=post>
[export_form_vars manual_id section_id]
<center>
<input type=submit value=\"Yes, Delete It\">
</center>
</form>

"

