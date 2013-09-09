# /www/manual/admin/manual-printable.tcl
ad_page_contract {
    Generate the printable versions of a document (HTML, PS, and PDF).
    Document generation is normally handled by a scheduled proc, but
    this script allows the administrator to force re-generation of the
    document after a set of changes.

    @param manual_id the ID of the manual we are generating
    @param return_url where to send the user back to

    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id manual-printable.tcl,v 1.4.2.3 2000/07/21 04:02:51 ron Exp
} {
    manual_id:integer,notnull
    {return_url ""}
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if ![ad_permission_p "manuals" $manual_id] {
    error "You are not authorized to access this page"
    }
}

# if ad_page_variables worked as claimed, we wouldn't have to do this

if [empty_string_p $return_url] {
    set return_url manual-view.tcl?manual_id=$manual_id 
}

# Assemble the manual and check for possible undefined references

set undefined_references [manual_assemble $manual_id]

set bad_sections [lindex $undefined_references 0]
set bad_figures  [lindex $undefined_references 1]
    
set section_msg ""
set figure_msg  ""

if {[llength $bad_sections] > 0 } {
    set section_msg "<li> Sections: [join $bad_sections ", "]"
}

if {[llength $bad_figures] > 0 } {
    set figure_msg "<li> Figures: [join $bad_figures ", "]"
}

if {![empty_string_p $section_msg] || ![empty_string_p $figure_msg]} {

    set title [db_string "
    select title from manuals 
    where manual_id = :manual_id"]

    doc_set_property title "Errors in manual"
    doc_set_property navbar [list \
	    [list "../" [manual_system_name]] \
	    [list "index.tcl" "Admin"] \
	    [list "manual-view.tcl?manual_id=$manual_id" $title] \
	    "Error"]

    doc_body_append "

    <h2>Undefined References</h2>

    We found some references in the text of the document that aren't
    in the database.  You should correct this and regenerate the
    printable versions. We can't tell you exactly where the errors are, 
    but here is the list of undefined references: 

    <ul>$section_msg</ul>

    <ul>$figure_msg</ul>

    "
} else {
    ad_returnredirect $return_url
}







