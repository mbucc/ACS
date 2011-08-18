#
# /www/education/class/admin/textbooks/edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# This confirms the information for the textbook
#

ad_page_variables {
    textbook_id
    publisher
    isbn
    author
    title
}


set exception_count 0
set exception_text ""

if {[empty_string_p $title]} {
    incr exception_count 
    append exception_text "<li>You must include a title for this book."
}


if {[empty_string_p $textbook_id]} {
    incr exception_count 
    append exception_text "<li>You must include an identification number for the book."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set class_id [lindex $id_list 1]

set validation_sql "select count(tb.textbook_id)
 from edu_textbooks tb,
      edu_classes_to_textbooks_map map
where tb.textbook_id = $textbook_id 
  and map.textbook_id = tb.textbook_id
  and map.class_id = $class_id"

if {[database_to_tcl_string $db $validation_sql] == 0} {
    ad_return_complaint 1 "<li>You are not authorized to edit this book."
    return
}


set return_string "
[ad_header "Textbooks @ [ad_system_name]"]

<h2>Confirm Edit Textbook Information</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "Class Home"] [list "../../textbook-info.tcl?textbook_id=$textbook_id "Text Book Information"] "Confrim Edit"]

<hr>
<blockquote>

<table>
<form method=post action=\"edit-3.tcl\">
<tr>
<th align=right>Title:</th>
<td>$title</td>
</tr>
<tr>
<th align=right>Author:</th>
<td>$author</td>
</tr>
<tr>
<th align=right>Publisher:</th>
<td>$publisher</td>
</tr>
<tr>
<th align=right>ISBN:</th>
<td>$isbn</td>
</tr>
[export_entire_form]
<tr><th></th>
<td><input type=submit value=Continue></td>
</tr>
</form>
</table>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string


