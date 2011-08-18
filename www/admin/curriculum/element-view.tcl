# $Id: element-view.tcl,v 3.0 2000/02/06 03:16:01 ron Exp $
#This file should be called element-view.tcl
#Called from element-list.tcl
set_the_usual_form_variables

# curriculum_element_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "
    select element_index, url, very_very_short_name, one_line_description, full_description
    from curriculum 
    where curriculum_element_id='[DoubleApos $curriculum_element_id]'"]
set_variables_after_query

#now we have the values from the database.

ReturnHeaders

ns_write "
[ad_admin_header "View the entry for $one_line_description"]

<h2>View the entry for $one_line_description</h2>

[ad_admin_context_bar [list "element-list.tcl" "Curriculum"] "View a curriculum element"]

<hr>

<table>
<tr><th valign=top align=right>Sequence (0 is the first element in the curriculum)</th>
<td> $element_index </td></tr>

<tr><th valign=top align=right>URL (start with / for internal, http: for external)</th>
<td> $url </td></tr>

<tr><th valign=top align=right>A very very short name (for the curriculum bar)</th>
<td> $very_very_short_name </td></tr>

<tr><th valign=top align=right>A full one-line description of this element</th>
<td> $one_line_description </td></tr>

<tr><th valign=top align=right>A full description of this element and why it is part of the curriculum</th>
<td> $full_description </td></tr>

</table>
<ul>
<li><a href=\"element-edit.tcl?[export_url_vars curriculum_element_id]\">Edit the data for $one_line_description</a><br>
</ul>
<p>
[ad_admin_footer]"
