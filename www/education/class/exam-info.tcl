# 
# /www/education/class/exam-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page displays information about a given exam
#

ad_page_variables {
    exam_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class student]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# check the input

set exception_text ""
set exception_count 0

if {![info exists exam_id] || [empty_string_p $exam_id]} {
    append exception_text "<li>You must include an identification number for this exam."
    incr exception_count
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set selection [ns_db 0or1row $db "select
             ea.class_id, 
             exam_name,
             class_name,
             teacher_id,
             first_names,
             last_name,
             ea.comments,
             ea.creation_date,
             last_modified,
             date_administered,
             grade_id,
             weight,
             fs.version_id, 
             fs.file_extension,
             fs.url,
             sol.version_id as sol_version_id, 
             sol.file_extension as sol_file_extension,
             sol.url as sol_url,
             online_p
        from edu_exams ea,
             users,
             edu_current_classes ec,
             (select * from fs_versions_latest 
              where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') fs,
             (select file_extension, url, version_id, task_id, ver.file_id 
                    from fs_versions_latest ver,
                         edu_task_solutions solutions
                   where ver.file_id = solutions.file_id
                     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') sol
       where ec.class_id = ea.class_id
         and users.user_id = ea.teacher_id
         and ea.exam_id = $exam_id
         and ea.exam_id = sol.task_id(+)
         and ea.file_id = fs.file_id(+)"]


if {$selection == ""} {
    ad_return_complaint 1 "There are no exams corresponding to the provided identification number.  The most likely cause for this is that the course administrator has closed this web page from the public."
    return
} else {
    set_variables_after_query
}
    



set return_string "
[ad_header "One Exam @ [ad_system_name]"]

<h2>$exam_name</h2>

[ad_context_bar_ws_or_index [list "one.tcl" "$class_name Home"] "One Exam"]

<hr>
<blockquote>


<table BORDER=0>

<tr>
<th valign=top align=right> Exam Name: </td>
<td valign=top>
"

if {![empty_string_p $url]} {
    append return_string "<a href=\"$url\">$exam_name</a>"
} elseif {![empty_string_p $version_id]} {
    append return_string "<a href=\"/file-storage/download/$exam_name.$file_extension?version_id=$version_id\">$exam_name</a>"
} else {
    append return_string "$exam_name"
}


append return_string "
</td>
</tr>

<tr>
<th valign=top align=right> Comments: </td>
<td valign=top>
[edu_maybe_display_text $comments]
</td>
</tr>

<tr>
<th valign=top align=right> Exam Date: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $date_administered]
</td>
</tr>

<tr>
<th valign=top align=right> Date Created: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $creation_date]
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
<th valign=top align=right>
Administered online?
</td>
<td valign=top>
[util_PrettyBoolean $online_p]
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
# if the student was evaluated and the person wants to let
# the student see this evaluation, show the student

set selection [ns_db select $db "select first_names || ' ' || last_name as grader_name, 
       grade, 
       user_id as grader_id,
       comments, 
       evaluation_date 
  from edu_student_evaluations,
       users
 where task_id = $exam_id 
   and show_student_p = 't'
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


if {![empty_string_p $sol_url]} {
    append return_string "<p><a href=\"$sol_url\">Solutions</a>"
} elseif {![empty_string_p $sol_version_id]} {
    append return_string "<p><a href=\"/file-storage/download/$exam_name-solutions.$sol_file_extension?version_id=$sol_version_id\">Solutions</a>"
} 



# we get multiple rows because it could be the case that multiple people reviewed
# the same student on the same exam (e.g. a prof and a TA could both review
# the same presentation

set selection [ns_db select $db "select first_names || ' ' || last_name as grader_name, 
       grade, 
       user_id as grader_id,
       comments, 
       show_student_p, 
       evaluation_date 
  from edu_student_evaluations,
       users
 where task_id = $exam_id 
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




