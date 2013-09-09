# /www/manual/admin/content-edit-abort.tcl
ad_page_contract {
    Abort editing a section.

    @param manual_id the manual being edited
    @param section_id the section being edited

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id content-edit-abort.tcl,v 1.3.2.2 2000/07/21 04:02:44 ron Exp
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
	error "You are not authorized to edit this manual"
    }
}

set editors_path [ns_info pageroot]/manuals/admin/editors/$user_id/${manual_id}.${section_id}.html

if [file exists $editors_path] {
    exec rm $editors_path
}

ad_returnredirect "section-edit.tcl?[export_url_vars manual_id section_id]"
