#
# /www/education/class/admin/task-delete.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page is where teachers can go to edit assignments (or projects).
# basically, they are able to upload a file/url into the file storage
# system and then associate a due date with it.
#

ad_page_variables {
    task_id
    task_type
    {return_url ""}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Delete Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


if {[empty_string_p $task_id] || [empty_string_p $task_type]} {
    ad_return_complaint 1 "<li>You must include a task to edit."
    return
}

set selection [ns_db 0or1row $db "select first_names as teacher_first_name,
                            last_name as teacher_last_name,
                            task_name,
                            description,
                            date_assigned,
                            last_modified,
                            due_date,
                            edu_student_tasks.file_id,
                            weight,
                            grade_id,
                            online_p,
                            requires_grade_p
                       from edu_student_tasks, 
                            users
                      where task_id = $task_id
                        and class_id = $class_id
                        and assigned_by = users.user_id"]

if { $selection == "" } {
    ad_return_complaint 1 "<li> The $task_type id you have provided does not exist.  Please check your identification number and try again."
    return
} else {
    set_variables_after_query
}


set return_string "
[ad_header "Delete [capitalize $task_type] @ [ad_system_name]"]

<h2>Delete [capitalize $task_type]</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Delete [capitalize $task_type]"]

<hr>

This $task_type was submitted by 
$teacher_first_name $teacher_last_name on 
[util_AnsiDatetoPrettyDate $date_assigned].  It was last 
updated on [util_AnsiDatetoPrettyDate $last_modified].<br><br>

<blockquote>

<form method=POST action=\"task-delete-2.tcl\">

[export_form_vars return_url file_id task_type task_id]

<table>
<tr>
<th valign=top align=right> [capitalize $task_type] Name: </td>
<td valign=top>
$task_name
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>

<tr>
<th align=right> Due Date: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $due_date]
</td>
</tr>

<tr>
<th valign=top align=right>Will this $task_type<br>be graded? </td>
<td valign=top>
[util_PrettyBoolean $requires_grade_p]
<tr>
<th align=right> Fraction of [capitalize $task_type] Grade: </td>
<td valign=top>
$weight \%
</td>
</tr>

<tr>
<th valign=top align=right> 
Will students submit <br>
answers electronically?
</td>
<td valign=top>
[util_PrettyBoolean $online_p]
</td>
</tr>
<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Delete [capitalize $task_type]\">
</td>
</tr>
</table>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
