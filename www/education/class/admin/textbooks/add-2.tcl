#
# /www/education/class/admin/textbooks/add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the user to confirm the information about the textbook
# they are about to add

ad_page_variables {
    title
    author
    {isbn ""}
    {comments ""}
    {publisher ""}
    {required_p f}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


#lets check the input
set exception_text ""
set exception_count 0

if {[empty_string_p $title]} {
    incr exception_count
    append exception_text "<li>You must provide a title."
}

if {[empty_string_p $author]} {
    incr exception_count
    append exception_text "<li>You must provide an author."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

if {[empty_string_p $isbn]} {
    set actual_isbn "None Provided"
} else {
    set actual_isbn $isbn
}



set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Add a Text Book</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] "Add a Text Book"]

<hr>

<blockquote>
"

# search if isbn is already in the db, if so, ask them if they just want to 
# add the textbook
set textbook_id [database_to_tcl_string_or_null $db "select textbook_id from edu_textbooks where isbn='$isbn'"]

if {![empty_string_p $textbook_id]} {
    ad_returnredirect "add-to-class.tcl?textbook_id=$textbook_id"
    return
} else {
    set textbook_id [database_to_tcl_string $db "select edu_textbooks_sequence.nextval from dual"]
}
    
append return_string "
<form method=get action=\"add-3.tcl\">
[export_form_vars title author isbn comments publisher required_p textbook_id]

<table>

<tr>
<th align=right>Title:</td>
<td>$title
</tr>

<tr>
<th align=right>Author:</td>
<td>$author
</tr>

<tr>
<th align=right>Publisher:</td>
<td>$publisher
</tr>

<tr>
<th align=right>ISBN:</td>
<td>$actual_isbn
</tr>

<tr>
<th align=right>Comments:</td>
<td>$comments
</tr>

<tr>
<th align=right>Required?</td>
<td>
[ad_html_pretty_boolean $required_p]
</td>
</tr>
<tr>
<td colspan=2 align=center><input type=submit value=\"Add Textbook\">
</td>
</tr>
</table>
</form>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string



