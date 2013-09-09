# /www/manual/admin/content-upload.tcl
ad_page_contract {
    Upload the text of a section

    @param manual_id the ID of the manual being added to
    @param section_id the ID of the section being uploaded
    @param comment a version control comment

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id content-upload.tcl,v 1.4.2.2 2000/07/21 04:02:46 ron Exp
} {
    manual_id:integer,notnull
    section_id:integer,notnull
    {comment ""}
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

db_1row manual_section_info "
select title,
       section_title
from   manuals m, manual_sections s
where  m.manual_id  = :manual_id
and    s.section_id = :section_id"

# -----------------------------------------------------------------------------

doc_set_property title "Upload Content"
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" "$title"] \
	[list "section-edit.tcl?[export_url_vars manual_id section_id]" "$section_title"] \
	"Upload Content"]

doc_body_append "
<p>Select the file to upload and enter a log message for your changes.</p>

<form action=content-upload-2 enctype=multipart/form-data method=POST>

[export_form_vars section_id manual_id]

<table>

<tr>
<th align=right>HTML file:</th>
<td><input type=file size=50 name=file_name></td>
</tr>

<tr>
<th align=right>Log Message:</th>
<td><input type=text name=comment size=50 value=\"$comment\"></td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit></td>
</tr>
</table>

</form>
"
