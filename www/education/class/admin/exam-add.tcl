#
# /www/education/class/admin/exam-add.tcl
#
# by aileen@mit.edu, randyg@arsdigita.com, January, 2000
#
# this page is where teachers can go to issue exams.
# they are able to upload a file/url into the file storage system.
#

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set return_string "
[ad_header "Add Exam @ [ad_system_name]"]

<h2>Add an Exam</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Add an Exam"]

<hr>

<blockquote>


<form method=post action=\"exam-add-2.tcl\">
<table>
<tr>
<th align=right>Exam Name: </td>
<td valign=top>
<input type=text size=30 maxsize=100 name=exam_name>
</td>
</tr>

<tr>
<th valign=top align=right>Comments: </td>
<td valign=top>
[edu_textarea comments "" 40 4]
</td>
</tr>

<tr>
<th align=right>Exam Date: </td>
<td valign=top>
[ad_dateentrywidget date_administered [database_to_tcl_string $db "select sysdate + 14 from dual"]]
</td>
</tr>

<tr>
<th align=right>Fraction of Exam Grades: </td>
<td>
<input type=text size=5 maxsize=10 name=weight>\% 
<font size=-1>
(This should be a percentage)
</font>
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
    <option value=$grade_id>$grade_name - $weight\%"
}

append return_string "
</select>
</td>
</tr>
<tr>
<th align=right> 
Administered online?
</td>
<td valign=top>
<input type=radio name=online_p value=t> Yes
<input type=radio name=online_p checked value=f> No
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





