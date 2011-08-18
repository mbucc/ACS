#
# /www/education/class/admin/textbooks/add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows a prof to add a textbook for the class

# it does not expect any input

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Class Properties"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Add a Text Book</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] "Add a Text Book"]

<hr>

To add a book, fill out the information below.  Providing the ISBN
number allows the system to search online book stores and price
compare.

<h3>Search if the textbook is already in the database</h3>
<form method=post action=\"search.tcl\">
By Title/Author/Publisher: <input type=text size=40 name=search_string>
<p>
By ISBN: <input type=text size=40 name=search_isbn>
<p>

<input type=submit value=Search>
</form>

<hr>
<form method=get action=\"add-2.tcl\">
<table>

<tr>
<th align=right>Title:</td>
<td><input type=text name=title size=30 maxsize=200></td>
</tr>

<tr>
<th align=right>Author:</td>
<td><input type=text name=author size=30 maxsize=400></td>
</tr>

<tr>
<th align=right>Publisher:</td>
<td><input type=text name=publisher size=30 maxsize=200></td>
</tr>

<tr>
<th align=right>ISBN:</td>
<td><input type=text name=isbn size=15 maxsize=30></td>
</tr>

<tr>
<th align=right>Comments:</td>
<td>[edu_textarea comments]</td>
</tr>

<tr>
<th align=right>Required?</th>
<td><input type=checkbox name=required_p value=t checked></td>
</tr>
<tr>
<td colspan=2 align=center><input type=submit value=Continue>
</td>
</tr>
</table>
</form>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string


