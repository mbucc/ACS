#
# /www/education/class/admin/student-evaluation-add-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows a user to add or edit an evaluation for a student
#

ad_page_variables {
    {student_id ""}
    {task_id ""}
    {return_url ""}
    {evaluation_id ""}
}

# we need for either (task_id and student_id) or evaluation_id to be not null


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# check the input

set exception_text ""
set exception_count 0


if {![empty_string_p $evaluation_id]} {
    ###################
    #                 #
    # this is an edit #
    #                 #
    ###################

    set selection [ns_db 1row $db "select grade, 
                    student_id, 
                    task_id, 
                    comments, 
                    show_student_p,
                    first_names || ' ' || last_name as student_name
               from edu_student_evaluations,
                    users
              where evaluation_id = $evaluation_id 
                and users.user_id = student_id
                and class_id = $class_id"]

    if {$selection == ""} {
	append exception_text "<li>The evaluation you are trying to edit either does not exist or does not belong to this class."
	incr exception_count
    } else {
	set_variables_after_query
    }

    set edit_p t
    set eval_action Edit

} else {
    ##################
    #                #
    # this is an add #
    #                #
    ##################

    if {![info exists student_id] || [empty_string_p $student_id]} {
	append exception_text "<li>You must designate which student you would like to evaluate </li> \n"
	incr exception_count
    } else {
	set student_name [database_to_tcl_string_or_null $db "select first_names || ' ' || last_name from users where user_id = $student_id"]
	if {[empty_string_p $student_id]} {
	    incr exception_count
	    append exception_text "<li>The student you have provided does not exist."
	}
    }
    
    # This is an ADD so lets set the variables

    set eval_action Add
    set grade ""
    set comments ""
    set show_student_p t
    set edit_p f

}

set pretty_roles [database_to_tcl_list $db "select pretty_role, pretty_role_plural from edu_role_pretty_role_map where lower(role) = lower('[edu_get_student_role_string]') and group_id = $class_id"]
set pretty_role [lindex $pretty_roles 0]
set pretty_role_plural [lindex $pretty_roles 1]

# get the task information if it exists

if {![empty_string_p $task_id]} {
    if {![info exists student_name]} {
	set student_name ""
    }
    set evaluation_pretty_type "[database_to_tcl_string_or_null $db "select task_name from edu_student_tasks where task_id = $task_id"]"
    
    # why do we have both evaluation_type and evaluation_pretty_type if they're both the same?
    set evaluation_type $evaluation_pretty_type
    if {[empty_string_p $evaluation_pretty_type]} {
	incr exception_count
	append exception_text "<li>The task you have requested does not exist."
    }

#    set export_string "[export_form_vars student_id task_id evaluation_pretty_type student_name return_url evaluation_id evaluation_type]"

    set evaluation_type_string "
    <tr>
    <th valign=top align=right>
    Evaluation Type:
    </td>
    <td>
    $evaluation_pretty_type
    </td>
    </tr>
    "
    set export_string "[export_form_vars student_id evaluation_type task_id evaluation_pretty_type student_name return_url evaluation_id]"

} else {
    if {![empty_string_p $evaluation_id]} {
	set evaluation_type [database_to_tcl_string $db "select evaluation_type from edu_student_evaluations where evaluation_id = $evaluation_id"]
    } else {
	set evaluation_type ""
    }

    set evaluation_type_string "
    <tr>
    <th align=right>
    Evaluation Type:
    </td>
    <td>
    <input type=text size=25 value=\"[philg_quote_double_quotes $evaluation_type]\" name=evaluation_type>
    </td>
    </tr>
    "
    
    set evaluation_pretty_type "$evaluation_type"

    # aileen - we shouldnt be passing around this many variables. we can derive evaluation_type and evaluation_pretty_type given the evaluation_id
    set export_string "[export_form_vars student_id task_id evaluation_pretty_type student_name return_url evaluation_id evaluation_type pretty_role pretty_role_plural]"
} else {
    incr exception_count
    append exception_text "<li>You must provide either an evaluation identification number or a task to be evaluated."
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



set return_string "
[ad_header "$eval_action a Student Evaluation @ [ad_system_name]"]

<h2>$eval_action $pretty_role Evaluation</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] "$eval_action $pretty_role Evaluation"]

<hr>
<blockquote>

<form method=post action=\"student-evaluation-add-edit-2.tcl\">
$export_string
<table>
<tr>
<th valign=top align=right>
$pretty_role:
</td>
<td>$student_name</td>
</tr>

$evaluation_type_string

<tr>
<th valign=top align=right>
Grade:
</td>
<td><input type=text size=5 maxsize=5 name=grade value=\"[philg_quote_double_quotes $grade]\">
</td>
</tr>

<tr>
<th valign=top align=right>
Comments:
</td>
<td>[edu_textarea comments $comments]
</td>
</tr>

<tr>
<th valign=top align=right>
Should the $pretty_role see<br>
this evaluation?
</td>
<td>
"

if {[string compare $show_student_p t] == 0} {
    append return_string "
    <input type=radio name=show_student_p value=t checked>Yes
    [ad_space 2] <input type=radio name=show_student_p value=f>No
    "
} else {
    append return_string "
    <input type=radio name=show_student_p value=t>Yes
    [ad_space 2] <input type=radio name=show_student_p value=f checked>No
    "
}

append return_string "
</td>
</tr>

<tr>
<td colspan=2 align=center>
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





