#
# /www/education/class/admin/task-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January, 2000
#
# this page is where teachers can go to issue tasks (assignments or projects)
# basically, they are able to upload a file/url into the file storage
# system and then associate a due date with it.
#

ad_page_variables {
    {task_type assignment}
}

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[string compare $task_type project] == 0} {
    set header "Add a Project"
} elseif {[string compare $task_type assignment] == 0} {
    set header "Add an Assignment"
} else {
    set header "Add an Exam"
}



set return_string "
[ad_header "$header @ [ad_system_name]"]

<h2>$header</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "$header"]

<hr>

<blockquote>


<form method=post action=\"task-add-2.tcl\">
[export_form_vars task_type]
<table>
<tr>
<th align=right> [capitalize $task_type] Name: </td>
<td valign=top>
<input type=text size=30 maxsize=100 name=task_name>
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_textarea description "" 50 6]
</td>
</tr>

<tr>
<th align=right> Due Date: </td>
<td valign=top>
[ad_dateentrywidget due_date [database_to_tcl_string $db "select sysdate + 14 from dual"]]
</td>
</tr>

<tr>
<th valign=top align=right>Will this $task_type<br>be graded? </td>
<td valign=top>
<input type=radio name=requires_grade_p checked value=t> Yes
<input type=radio name=requires_grade_p value=f> No
</tr>

<tr>
<th  align=right>Fraction of [capitalize $task_type] Grades: </td>
<td valign=top>
<input type=text size=5 maxsize=10 name=weight>\% 
</td>
</tr>
<tr>
<th align=right>Grade Policy Group</th>
<td valign=top>
<select name=grade_id>
<option value=\"\">None
"

set selection [ns_db select $db "select grade_name, weight, grade_id from edu_grades where class_id=$class_id order by grade_name"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <option value=$grade_id>$grade_name -$weight\%"
}

append return_string "
</select>
</td>
</tr>
<tr>
<th valign=top align=right> 
Will students submit <br>
answers electronically?
</td>
<td valign=top>
<input type=radio name=electronic_submission_p value=t> Yes
<input type=radio name=electronic_submission_p checked value=f> No
</font>
</td>
</tr>

</td>
</tr>
<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Continue\">
</td>
</tr>
</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string

