# /www/manuals/admin/figure-add.tcl
ad_page_contract {
    Upload a new figure to the database

    @param manual_id the ID of the manual we are adding to

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Jan 2000
    @cvs-id figure-add.tcl,v 1.4.2.2 2000/07/21 04:02:47 ron Exp
} {
    manual_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}

db_1row title "select title from manuals where manual_id = :manual_id"

# -----------------------------------------------------------------------------

doc_set_property title "Add Figure"
doc_set_property navbar [list \
	[list "../" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" "$title"] \
	[list "figures.tcl?manual_id=$manual_id" "Figures"] \
	"Add Figure"]

doc_body_append "
<form enctype=multipart/form-data method=POST action=figure-add-2>

[export_form_vars manual_id]

<table>

<tr>
<th align=right>Label:</th>
<td><input type=text size=50 name=label></td>
</tr>

<tr>
<th align=right>Image File:</td>
<td><input type=file size=50 name=file_name></td>
</tr>

<tr>
<th align=right valign=top>Caption:</th>
<td><textarea name=caption rows=10 cols=80 wrap=soft></textarea></td>
</tr>

[manual_radio_widget numbered_p "Numbered" "t"]

<tr>
<td></td>
<td><input type=submit value=Submit></td>
</tr>

</table>
</form>
"

