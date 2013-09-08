# /www/manual/admin/figure-edit.tcl
ad_page_contract {
    Edit a figure, including its caption, label, and possibly the image file.

    @param manual_id the ID of the manual
    @param figure_id the ID of the figure being edited

    @author Kevin Scaldeferri (kevin@caltech.edu)
    @creation-date Feb 2000
    @cvs-id figure-edit.tcl,v 1.4.2.4 2000/07/21 23:58:03 kevin Exp
} {
    manual_id:integer,notnull
    figure_id:integer,notnull
}

# -----------------------------------------------------------------------------

# Verify the editor

page_validation {
    if {![ad_permission_p "manuals" $manual_id]} {
	error "You are not authorized to edit this manual"
    }
}


# Grab the information for this figure

db_1row figure_info "
select title,
       caption,
       label,
       width,
       height,
       numbered_p
from   manuals m, manual_figures f
where  f.figure_id = :figure_id
and    m.manual_id = f.manual_id"

set filename [manual_get_image_file $figure_id]

# -----------------------------------------------------------------------------

doc_set_property title "Edit Figure"
doc_set_property navbar [list \
	[list "/manuals" [manual_system_name]] \
	[list "index.tcl" "Admin"] \
	[list "manual-view.tcl?manual_id=$manual_id" "$title"] \
	[list "figures.tcl?manual_id=$manual_id" "Figures"] \
	"Edit Figure"]

doc_body_append "
<p>

Modify the caption and/or upload a new image.

<p>

<form enctype=multipart/form-data method=POST action=figure-edit-2>
[export_form_vars manual_id figure_id]
<table>

<tr>
<th align=right>Label:</th>
<td><input type=text name=label size=30 value=\"$label\">
</tr>

<tr>
<th align=right>Caption:</th>
<td><textarea name=caption rows=10 cols=80 wrap=soft>$caption</textarea></td>
</tr>

[manual_radio_widget numbered_p "Numbered"]

<tr>
<th>Upload Image File:</th>
<td><input type=file name=file_name size=50><br>
<font size=-1>Only use this if you want to upload a new image file</font>
</td>
</tr>

<tr>
<td></td>
<td><input type=submit value=Submit></td>
</tr>

</table>
</form>

<h4>Extreme Actions:</h4>

<ul>
<li><a href=figure-delete?figure_id=$figure_id>Delete this figure</a>
</ul>

<hr>

<p>

<center>
<img src=$filename width=$width height=$height alt=\"$label\"></a>
</center>

"
