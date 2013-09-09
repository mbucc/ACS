# /www/admin/curriculum/element-edit.tcl

ad_page_contract {
    This file should be called element-edit.tcl
    Called from element-list.tcl
    @author unknown
    @cvs-id element-edit.tcl,v 3.2.2.5 2000/09/22 01:34:39 kevin Exp
    @param curriculum_element_id The curriculum element to edit
} {
    curriculum_element_id
}

ad_maybe_redirect_for_registration

if {[catch {db_1row  get_element_to_edit "select element_index, url, very_very_short_name, one_line_description, full_description
    from curriculum 
    where curriculum_element_id=:curriculum_element_id"} errmsg]} {
    ad_return_error "Error in finding the data" "We encountered an error in querying the database for your object.
Here is the error that was returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>"
    return
} 



#now we have the values from the database.


set body "[ad_admin_header "Edit the entry for $one_line_description"]

<h2>Edit the entry for $one_line_description</h2>

[ad_admin_context_bar [list "element-list.tcl" "Curriculum"] "Edit a curriculum element"]

<hr>

<form method=POST action=element-edit-2>
[export_form_vars curriculum_element_id]" 

# Make the forms:

append body "<table>
<tr><th valign=top align=right>Sequence (0 is the first element in the curriculum)</th>
<TD><input type=text size=10 MAXLENGTH=22 name=element_index [export_form_value element_index]></TD></TR>

<tr><th valign=top align=right>URL (start with / for internal, http: for external)</th>
<td><input type=text size=70 MAXLENGTH=200 name=url [export_form_value url]></td></tr>

<tr><th valign=top align=right>A very very short name (for the curriculum bar)</th>
<td><input type=text size=40 MAXLENGTH=30 name=very_very_short_name [export_form_value very_very_short_name]></td></tr>

<tr><th valign=top align=right>A full one-line description of this element</th>
<td><input type=text size=70 MAXLENGTH=200 name=one_line_description [export_form_value one_line_description]></td></tr>

<tr><th valign=top align=right>A full description of this element and why it is part of the curriculum</th>
<td><textarea name=full_description cols=40 rows=15 wrap=soft>[ns_quotehtml $full_description]</textarea></td></tr>

</table>
<p>
<center>
<input type=submit value=\"Edit $one_line_description\">
</center>
</form>
<p>
[ad_admin_footer]"




doc_return  200 text/html $body