#
# /www/education/class/assignment-info.tcl
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# this class shows a user the assigment requested as well as the solutions
# and everything else related to this user and the pset.
#

ad_page_variables {
    assignment_id
}


set db [ns_db gethandle]

# lets get the class_id

# get all of the assignments.  If there are solutions, get those.
# if the student has uploaded their answers, get those as well

set user_id [ad_verify_and_get_user_id]

set selection [ns_db 0or1row $db "select
             ea.class_id, 
             ea.assignment_name,
             ec.class_name,
             ea.teacher_id,
             first_names,
             last_name,
             ea.description,
             ea.date_assigned,
             ea.last_modified,
             ea.due_date,
             ea.grade_id,
             ea.weight,
             ea.electronic_submission_p,
             ea.requires_grade_p,
             ver.version_id, 
             ver.file_extension,
             ver.url,
             sol.version_id as solution_version_id, 
             sol.file_extension as solution_file_extension,
             sol.url as solution_url,
             answers.version_id as answers_version_id, 
             answers.file_extension as answers_file_extension,
             answers.url as answers_url,
             ec.public_p
        from edu_assignments ea,
             users,
             edu_current_classes ec,
             (select * from fs_versions_latest 
              where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') ver,
             (select file_extension, url, version_id, task_id 
                    from fs_versions_latest ver,
                         edu_task_solutions solutions
                   where ver.file_id = solutions.file_id
                     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
                     and task_id = $assignment_id) sol,
            (select file_extension, file_title, url, version_id, task_id
                    from fs_versions_latest ver,
                         edu_student_answers ans,
                         fs_files
                   where ver.file_id = ans.file_id 
                     and fs_files.file_id = ver.file_id
                     and student_id = $user_id
                     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
                     and task_id=$assignment_id) answers
       where ec.class_id = ea.class_id
         and users.user_id = ea.teacher_id
         and ea.assignment_id = $assignment_id
         and ea.file_id = ver.file_id(+)
         and ea.assignment_id = sol.task_id(+)
         and ea.assignment_id = answers.task_id(+)"]



if {$selection == ""} {
    ad_return_complaint 1 "There are no assignments corresponding to the provided identification number.  The most likely cause for this is that the course administrator has closed this course from the public."
    return
} else {
    set_variables_after_query
}
    

set return_url [ad_partner_url_with_query]


# if the class is private, make sure the user is logged in correctly

if {[string compare $public_p f] == 0} {
    
    set id_list [edu_group_security_check $db edu_class [edu_get_student_role_string]]
    set user_id [lindex $id_list 0]
    set actual_class_id [lindex $id_list 1]
    set class_name [lindex $id_list 2]

    if {[string compare $actual_class_id $class_id] != 0} {
	# the user is logged in as member of a different class
	ad_returnredirect "/education/util/group-select.tcl?group_name=$group_name&group_id=$group_id&type=$group_type&return_url=[ns_urlencode $return_url]"
	return
    }
}


set return_string "
[ad_header "One Assignment @ [ad_system_name]"]

<h2>$assignment_name</h2>

[ad_context_bar_ws_or_index [list "" "All Classes"] [list "one.tcl" "$class_name Home"] "One Assignment"]

<hr>
<blockquote>


<table BORDER=0>

<tr>
<th valign=top align=right> Assignment Name: </td>
<td valign=top>
"

if {![empty_string_p $url]} {
    append return_string "<a href=\"$url\">$assignment_name</a>"
} elseif {![empty_string_p $version_id]} {
    append return_string "<a href=\"/file-storage/download/$assignment_name.$file_extension?version_id=$version_id\">$assignment_name</a>"
} else {
    append return_string "$assignment_name"
}

append return_string "
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>

<tr>
<th valign=top align=right> Due Date: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $due_date]
</td>
</tr>

<tr>
<th valign=top align=right> Date Assigned: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $date_assigned]
</td>
</tr>

<tr>
<th valign=top align=right>Will this assignment<br>be graded? </td>
<td valign=top>
[util_PrettyBoolean $requires_grade_p]
</td>
</tr>

<tr>
<th valign=top align=right> Fraction of Final Grade: </td>
<td valign=top>"

if {[empty_string_p $weight]} {
    append return_string "N/A"
} else {
    append return_string "$weight"
}

append return_string "
</td>
</tr>
<tr>
<th align=right>Grade Group</th>
<td>"

if {![empty_string_p $grade_id]} {
    set selection [ns_db 0or1row $db "select grade_name, weight from edu_grades where grade_id = $grade_id"]
} else {
    set selection ""
}


if {$selection!=""} {
    set_variables_after_query
} else {
    set grade_name ""
    set weight ""
}

append return_string "
[edu_maybe_display_text $grade_name] [ec_decode $weight "" "" "- $weight %"]
</td></tr>
<tr>
<th valign=top align=right>
Will students submit <br>
answers electronically?
</td>
<td valign=top>
[util_PrettyBoolean $electronic_submission_p]
</td>
</tr>

<tr>
<th valign=top align=right> Assigned By: </td>
<td valign=top>
$first_names $last_name
</td>
</tr>

<tr>
<th valign=top align=right> Last Modified: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $last_modified]
</td>
</tr>


</table>
"

if {[string compare $electronic_submission_p t] == 0} {
    set submit_solutions_text "Submit/Update Answers"
    
    if {![empty_string_p $answers_url]} {
	append return_string "<p> <a href=\"$answers_url\">Your Answers</a>"
	set submit_solutions_text "Update Your Answers"
    } elseif {![empty_string_p $answers_version_id]} {
	append return_string "<p> <a href=\"/file-storage/download/$assignment_name-Answers.$answers_file_extension?version_id=$answers_version_id\">Your Answers</a>"
	set submit_solutions_text "Update Your Answers"
    } 	    
}


if {![empty_string_p $solution_url]} {
    append return_string "<p><a href=\"$solution_url\">Solutions</a>"
} elseif {![empty_string_p $solution_version_id]} {
    append return_string "<p><a href=\"/file-storage/download/$assignment_name-solutions.$solution_file_extension?version_id=$solution_version_id\">Solutions</a>"
} else {
    if {[string compare $electronic_submission_p t] == 0 && [ad_permission_p $db "" "" "Submit Tasks" $user_id $class_id]} {
	append return_string "<p><a href=\"task-turn-in.tcl?task_id=$assignment_id&task_type=assignment&[export_url_vars return_url]\">$submit_solutions_text</a>"
    }
}



# we get multiple rows because it could be the case that multiple people reviewed
# the same student on the same assigment (e.g. a prof and a TA could both review
# the same presentation

set selection [ns_db select $db "select first_names || ' ' || last_name as grader_name, 
       grade, 
       user_id as grader_id,
       comments, 
       show_student_p, 
       evaluation_date 
  from edu_student_evaluations,
       users
 where task_id = $assignment_id 
   and users.user_id = grader_id
   and student_id = $user_id"]

set public_eval_count 0
set eval_string ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if {[string compare $show_student_p t] == 0} {
	append eval_string "
	<li>
	Grade:
	[edu_maybe_display_text $grade]
	</li>
	
	<li>
	Comments:
	[edu_maybe_display_text $comments]
	</li>
	
	<li>
	Graded By: $grader_name
	</li>
	<p>
	"

	incr public_eval_count
    }
}

if {$public_eval_count > 0} {
    if {$public_eval_count == 1} {
	append return_string "<h3>Your Evaluation</h3>"
    } else {
	append return_string "<h3>Your Evaluations</h3>"
    }
    
    append return_string "
    <ul>
    $eval_string
    </ul>
    "
}


append return_string "
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string








