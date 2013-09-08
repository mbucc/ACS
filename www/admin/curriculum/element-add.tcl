# /www/admin/curriculum/element-add.tcl

ad_page_contract {
    Code for element-add.tcl
    @author unknown
    @cvs-id element-add.tcl,v 3.2.2.6 2001/01/10 17:04:40 khy Exp
} {}

ad_maybe_redirect_for_registration


set curriculum_element_id [db_nextval "curriculum_element_id_sequence"]

set body  "
[ad_admin_header "Add a curriculum element"]

<h2>Add a curriculum element</h2>

[ad_admin_context_bar [list "element-list" "Curriculum"] "Add a curriculum element"]

<hr>

<form method=POST action=\"element-add-2\"> 

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
[export_form_vars -sign curriculum_element_id]
<p>
<center>
<input type=submit value=\"Add the curriculum element\">
</center>
</form>
<p>
[ad_admin_footer]"



doc_return  200 text/html $body

