# $Id: element-add.tcl,v 3.0 2000/02/06 03:15:56 ron Exp $
#Code for element-add.tcl

ad_maybe_redirect_for_registration
set db [ns_db gethandle]
ReturnHeaders 


ns_write "
[ad_admin_header "Add a curriculum element"]

<h2>Add a curriculum element</h2>

[ad_admin_context_bar [list "element-list.tcl" "Curriculum"] "Add a curriculum element"]

<hr>

<form method=POST action=\"element-add-2.tcl\"> 

<table>
<tr><th valign=top align=right>Sequence (0 is the first element in the curriculum)</th>
<td><input type=text size=10 name=element_index MAXLENGTH=22></td></tr>

<tr><th valign=top align=right>URL (start with / for internal, http: for external)</th>
<td><input type=text size=70 name=url MAXLENGTH=200>
<br>
<font size=-1>note that a URL ending in / doesn't work with this package; 
you need to include the \"index.html\" or \"index.tcl\" or whatever.</font>

</td></tr>

<tr><th valign=top align=right>A very very short name (for the curriculum bar)</th>
<td><input type=text size=40 name=very_very_short_name MAXLENGTH=30></td></tr>

<tr><th valign=top align=right>A full one-line description of this element</th>
<td><input type=text size=70 name=one_line_description MAXLENGTH=200></td></tr>

<tr><th valign=top align=right>A full description of this element and why it is part of the curriculum</th>
<td><textarea name=full_description cols=40 rows=15 wrap=soft></textarea></td></tr>

</table>
<input type=hidden name=curriculum_element_id value=\"[database_to_tcl_string $db "
select curriculum_element_id_sequence.nextval from dual"]\">
<p>
<center>
<input type=submit value=\"Add the curriculum element\">
</center>
</form>
<p>
[ad_admin_footer]"
