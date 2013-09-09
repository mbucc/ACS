# /www/manuals/admin/section-edit.tcl
ad_page_contract {
    Allows the user the edit the parameters for a section, and provides
    a link to edit the content.

    @param manual_id the ID of the manual
    @param section_id the ID of the section being edited

    @author Ron Henderson (ron@arsdigita.com)
    @creation-date Feb 2000
    @cvs-id section-edit.tcl,v 1.4.2.2 2000/07/21 04:02:55 ron Exp
} {
    manual_id:integer,optional
    section_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

# if we didn't get manual_id, find it

if ![info exists manual_id] {
    db_1row manual_id "
    select manual_id from manual_sections where section_id = :section_id"
}

# Get the data for this section

db_1row info_for_one_section "
select section_title,
       label,
       content_p,
       sort_key as root_key
from   manual_sections
where  section_id = :section_id"

# Get the title of the manual we're working on

db_1row title "select title from manuals where manual_id = :manual_id"

# Get this section's parent

set parent_sort_key [manual_get_parent $root_key]

if {[db_0or1row parent_info "
select section_title as parent_title,
       section_id    as parent_id
from   manual_sections
where  manual_id = :manual_id
and    sort_key  = :parent_sort_key"]} {

    set section_parent "<a href=section-edit?section_id=$parent_id&manual_id=$manual_id>
    $parent_title</a>"
} else {
    set section_parent "<a href=manual-view?manual_id=$manual_id>$title</a>"
}

# Get the list of children

set section_children ""
set root_key_base "${root_key}%"

db_foreach section_childen "
select   section_id    as child_id,
         section_title as child_title,
         sort_key      as child_key,
         length(sort_key)-[string length $root_key]-2 as depth
from     manual_sections
where    manual_id = :manual_id
and      active_p  = 't'
and      section_id <> :section_id
and      sort_key like :root_key_base
order by child_key" {

    append section_children "[manual_spacer $depth]
    <a href=section-edit?section_id=$child_id&manual_id=$manual_id>$child_title</a><br>"
} if_no_rows {
    set section_children "None"
}

# Get the content for display (if available)

if {$content_p == "t"} {
    set section_content [manual_parse_section $manual_id $section_id]
    set section_options "
    <a href=content-edit?[export_url_vars section_id manual_id]>Edit</a> | 
    <a href=content-upload?[export_url_vars section_id manual_id]>Upload</a> |
    <a href=content-history?[export_url_vars section_id manual_id]>Revision History</a>"
} else {
    set section_content "None"
    set section_options "
    <a href=content-upload?[export_url_vars section_id manual_id]>Upload</a>"
}

# -----------------------------------------------------------------------------

doc_set_property title "Edit Section"
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" "$title"] \
	"Edit Section"]

doc_body_append "

<form action=section-edit-2 method=post>

[export_form_vars section_id manual_id]

<table>

<tr>
<th align=right>Section Title:</th>
<td><input type=text size=60 name=section_title value=\"$section_title\"></td>
</tr>

<tr>
<th align=right>Label:</th>
<td><input type=text size=20 maxlength=20 name=label value=\"$label\"></td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Update></td>
</tr>

</table>

</form>

<h4>Parent</h4>

$section_parent

<h4>Subsections</h4>

$section_children

<h3>Extreme Actions</h3>

<ul>
<li><a href=section-delete?[export_url_vars section_id manual_id]>Delete this section</a>
</ul>

<p>
<table bgcolor=#cccccc width=100% cellpadding=2>
<tr>
<th>Content</th>
</tr>
</table>
<table width=100%>
<tr>
<td align=right>
$section_options
</td>
</tr>
</table>

<p>
$section_content
<p>

"


