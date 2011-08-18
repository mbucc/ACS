#
# /www/education/class/admin/users/student-evaluation-add-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the user to confirm the information entered as the 
# student's evaluation
#


ad_page_variables {
    student_id
    task_id
    evaluation_pretty_type
    student_name
    {return_url ""}
    {grade ""}
    {evaluation_id ""}
    {comments ""}
    {show_student_p t}
    evaluation_type
    {pretty_role Student}
    {pretty_role_plural Students}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[empty_string_p $evaluation_id]} {
    set evaluation_id [database_to_tcl_string $db "select edu_evaluation_id_sequence.nextval from dual"]
    set eval_action Add
} else {
    # if there is an evaluation_id, lets make sure it is an evaluation for this class
    if {[database_to_tcl_string $db "select count(evaluation_id) from edu_student_evaluations where evaluation_id = $evaluation_id and class_id = $class_id"] == 0} {
	ad_return_complaint 1 "<li> The evaluation you are trying to edit does not belong to this class."
	return
    }
    set eval_action Edit
}

ns_db releasehandle $db


if {[empty_string_p $evaluation_pretty_type]} {
    set evaluation_pretty_type $evaluation_type
}



append string_return "
[ad_header "Edit a $pretty_role Evaluation @ [ad_system_name]"]

<h2>$eval_action $pretty_role Evaluation</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] "$eval_action $pretty_role Evaluation"]

<hr>
<blockquote>

<form method=post action=\"student-evaluation-add-edit-3.tcl\">
[export_form_vars student_id task_id student_name return_url evaluation_id grade comments show_student_p evaluation_type]

<table>
<tr>
<th valign=top align=right>
$pretty_role:
</td>
<td>$student_name</td>
</tr>

<tr>
<th valign=top align=right>
Evaluation Type:
</td>
<td>
$evaluation_pretty_type
</td>
</tr>

<tr>
<th valign=top align=right>
Grade:
</td>
<td>$grade
</td>
</tr>

<tr>
<th valign=top align=right>
Comments:
</td>
<td>$comments
</td>
</tr>

<tr>
<th valign=top align=right>
Should the $pretty_role see <br>
this evaluation?
</td>
<td>[util_PrettyBoolean $show_student_p]
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br><br>
<input type=submit value=\"$eval_action Student Evaluation\">
</td>
</tr>

</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







