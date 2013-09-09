# manuals/admin/section-add.tcl
ad_page_contract {
    page to add a new table of contents item

    @param manual_id the ID of the manual we are adding to
    @param parent_key the sort key of the parent to this item

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id section-add.tcl,v 1.4.2.3 2000/07/21 04:02:53 ron Exp
} {
    manual_id:integer,notnull
    {parent_key ""}
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

if [empty_string_p $parent_key] {
    set parent_title "Top"
} else {
    db_1row parent_title "
    select section_title as parent_title
    from   manual_sections
    where  manual_id = :manual_id
    and    sort_key  = :parent_key"
}

db_1row title "
select title from manuals 
where manual_id = :manual_id"

db_release_unused_handles

# -----------------------------------------------------------------------------

doc_set_property title "Add Section Under $parent_title"
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" $title] "Add Section"]

doc_body_append "
<form enctype=multipart/form-data method=post action=section-add-2>

[export_form_vars manual_id parent_key]

<table>
  <tr>
    <th align=right>Section Title:</th>
    <td><input type=text size=60 name=section_title></td>
  </tr>
  <tr>
    <th align=right>Label:</th>
    <td><input type=text size=20 maxlength=20 name=label></td>
  </tr>
  <tr>
    <th align=right>HTML file (optional):</th>
    <td><input type=file size=50 maxlength=300 name=file_name></td>
  </tr>
  <tr>
    <td></td>
    <td><input type=submit value=Submit></td>
  </tr>
</table>
</form>

<p>If you want to add content to this section, give the name of a
file containing the HTML, or click 'browse' to locate the file on your
local hard drive.  If you want to cross-reference this section in
other areas of the document, provide a short label for it.</p>

"

