#
# /www/education/class/admin/textbooks/add-to-class.tcl
#
# this page confirms that you want to add the given text book to the given class
# 
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#

ad_page_variables {
    textbook_id
}


if {[empty_string_p $textbook_id]} {
    ad_return_complaint 1 "<li>You must include a textbook to be added."
    return
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set selection [ns_db 0or1row $db "select * from edu_textbooks where textbook_id=$textbook_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>You called this page with an invalid textbook ID"
    return
}

set_variables_after_query


set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Add a Text Book</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] "Add a Text Book"]

<hr>

<blockquote>

<form method=get action=\"add-to-class-2.tcl\">
[export_form_vars textbook_id]

<p>
<table>
<tr>
<th align=right>Title:</td>
<td>$title</td>
</tr>

<tr>
<th align=right>Author:</td>
    <td>$author</td>
</tr>
    
<tr>
<th align=right>Publisher:</td>
<td>$publisher</td>
</tr>

<tr>
<th align=right>ISBN:</td>
<td>$isbn</td>
</tr>

<tr>
<th align=right>Comments:</td>
<td>[edu_textarea comments]</td>
</tr>

<tr>
<th align=right>Required?</td>
<td><input type=checkbox name=required_p value=t checked></td>
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


