# /www/manuals/admin/manual-view.tcl
ad_page_contract {
    Administrative controls for a single manual

    @param manual_id the ID of the manual to view

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id manual-view.tcl,v 1.5.2.3 2000/07/21 04:02:52 ron Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if ![ad_permission_p "manuals" $manual_id] {
	error "You are not authorized to access this page"
    }
}

db_1row title "
select title from manuals 
where manual_id = :manual_id"

if [ad_parameter UseHtmldocP manuals] {
    set printable_link "<li><a href=manual-printable?manual_id=$manual_id>Generate printable versions</a>"
} else {
    set printable_link ""
}



# -----------------------------------------------------------------------------

doc_set_property title $title
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	$title]

doc_body_append "
[help_upper_right_menu \
	[list "/manuals/manual-view.tcl?manual_id=$manual_id" "User Pages"] \
	[list "figures.tcl?manual_id=$manual_id" "Figures"] \
	[list "/doc/manuals.html" "Help"]]

<h3> Contents </h3>

[manual_toc_admin $manual_id]

<h3>Other Actions:</h3>
<ul>
$printable_link
</ul>

"

