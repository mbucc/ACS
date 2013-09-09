# /www/manual/admin/content-history.tcl
ad_page_contract {
    Show the revision history of a content file

    @param manual_id the ID of the manual being looked at
    @param section_id the ID of the section being looked at

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id content-history.tcl,v 1.3.2.2 2000/07/21 04:02:45 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
}

# -----------------------------------------------------------------------------

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to view this page"
    }

    if ![ad_parameter UseCvsP manuals] {
	# No revision history is available unless we're using CVS.
	error "Revision history is not available"
    }
}

db_1row manual_section_info "
select m.title,
       s.section_title,
       s.content_p
from   manuals m, manual_sections s
where  m.manual_id  = :manual_id
and    s.section_id = :section_id"

# Make sure there is something to look at!  This cannot happen if a
# user navigates to this page the normal way, so it must be an error. 

page_validation {
    if {$content_p == "f"} {
	error "This section has no content"
    }
}

# Fetch the revision history for this section from CVS

set filename ${manual_id}.${section_id}.html
set content_file [ns_info pageroot]/manuals/sections/$filename
set log [vc_fetch_log  $content_file]

doc_set_property title "Content Revision History"
doc_set_property navbar [list \
        [list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" $title] \
	[list "section-edit.tcl?[export_url_vars manual_id section_id]" "$section_title"] \
	"Revision History"]

doc_body_append "
<pre>$log</pre>
"


