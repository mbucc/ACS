#
# /www/education/class/admin/textbooks/edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page allows the user to edit the properties of a particular textbook
#

ad_page_variables {
    textbook_id
}


if {[empty_string_p $textbook_id]} {
    ad_return_complaint 1 "<li>You must provide a textbook identification number.
    return
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set class_id [lindex $id_list 1]

set selection [ns_db 0or1row $db "select title, 
      author, 
      publisher, 
      isbn 
 from edu_textbooks tb,
      edu_classes_to_textbooks_map map
where tb.textbook_id = $textbook_id 
  and map.textbook_id = tb.textbook_id
  and map.class_id = $class_id"]


if {$selection == ""} {
    ad_return_complaint 1 "<li>The textbook identification number you have provided is not valid."
    return
} else {
    set_variables_after_query
}


set return_string "
[ad_header "Textbooks @ [ad_system_name]"]

<h2>Edit Textbook Information</h2>

[ad_context_bar_ws_or_index [list "../" "Class Home"] [list "../../textbook-info.tcl?textbook_id=$textbook_id" "Text Book Information"] "Edit"]

<hr>
<blockquote>

<table>
<form method=post action=\"edit-2.tcl\">
<tr>
<th align=right>Title:</th>
<td><input type=text size=40 value=\"$title\" name=title></td>
</tr>
<tr>
<th align=right>Author:</th>
<td><input type=text size=40 value=\"$author\" name=author></td>
</tr>
<tr>
<th align=right>Publisher:</th>
<td><input type=text size=40 value=\"$publisher\" name=publisher></td>
</tr>

<tr>
<th align=right>ISBN:</th>
<td><input type=text size=40 value=\"$isbn\" name=isbn></td>
</tr>

[export_form_vars textbook_id]
<tr><th></th>
<td><input type=submit value=Submit></td>
</tr>
</form>
</table>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string














