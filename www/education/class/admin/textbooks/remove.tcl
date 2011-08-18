#
# /www/education/class/admin/textbooks/remove.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page confirms that the user wants to remove this textbook from the class
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
set class_name [lindex $id_list 2]
set user_id [lindex $id_list 0]

set selection [ns_db 0or1row $db "select title, author, publisher, isbn from edu_textbooks where textbook_id = $textbook_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>The textbook identification number you have provided is not valid."
    return
} else {
    set_variables_after_query
}


set return_string "
[ad_header "Textbooks @ [ad_system_name]"]

<h2>Remove a Textbook</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "$class_name Administration"] "Remove Textbook"]

<hr>
<b>Are you sure you want to remove the following textbook from $class_name?</b>
<p>
<blockquote>
<form method=post action=\"remove-2.tcl\">
[export_form_vars textbook_id]

<table>
<tr><th align=right>Title:</th>
<td>$title</td>
</tr>

<tr>
<th align=right>Author:</th>
<td>$author</td>
</tr>

<tr>
<th align=right>Publisher:</th>
<td>[edu_maybe_display_text $publisher]</td>
</tr>

<tr>
<th align=right>ISBN:</th>
<td>[edu_maybe_display_text $isbn]</td>
</tr>

<tr>
<th></th>
<td><input type=submit value=Confirm></td>
</tr>
</table>
</form>
</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string

