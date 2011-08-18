#
# /www/education/class/admin/exam-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page displays information about a given exam
#

ad_page_variables {
    exam_id
}


set db [ns_db gethandle]


# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "View Admin Pages"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set return_url [ad_partner_url_with_query]

# check the input

set exception_text ""
set exception_count 0

if {[empty_string_p $exam_id]} {
    append exception_text "<li>You must include an identification number for this exam."
    incr exception_count
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set selection [ns_db 0or1row $db "select
             ea.class_id,
             files.file_id,
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
             files.version_id, 
             files.file_extension,
             files.url,
             sol.file_id as sol_file_id,
             sol.version_id as sol_version_id, 
             sol.file_extension as sol_file_extension,
             sol.url as sol_url,
             online_p
        from edu_exams ea,
             users,
             edu_classes ec,
             (select * from fs_versions_latest 
              where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') files,
             (select sol.file_id, version_id, file_extension, url, task_id
              from edu_task_solutions sol, 
                   fs_versions_latest ver
              where task_id = $exam_id
                and sol.file_id = ver.file_id
                and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') sol
       where ec.class_id = ea.class_id
         and users.user_id = ea.teacher_id
         and ea.exam_id = $exam_id
         and ea.exam_id = sol.task_id(+)
         and ea.file_id = files.file_id(+)"]

if {$selection == ""} {
    ad_return_complaint 1 "There are no exams corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
    return
} else {
    set_variables_after_query
}
    



set return_string "
[ad_header "One Exam @ [ad_system_name]"]

<h2>$exam_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" Administration] "One Exam"]

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
<th valign=top align=right> Fraction within Grade Group: </td>
<td valign=top>"

if {[empty_string_p $weight]} {
    append return_string "N/A"
} else {
    append return_string "$weight \%"
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
</form>
<p>
"

set display_list [list]

set user_has_edit_permission_p [ad_permission_p $db "" "" "Edit Tasks" $user_id $class_id]

if {$user_has_edit_permission_p} { 
    lappend display_list "<a href=\"exam-edit.tcl?&exam_id=$exam_id&[export_url_vars return_url]\">edit</a>"
}

set task_type exam
set task_id $exam_id

if {$user_has_edit_permission_p} {
    if {![empty_string_p $file_id]} {
	lappend display_list "<a href=\"task-file-new.tcl?task_id=$task_id&task_type=exam&[export_url_vars return_url]\">upload new file</a>"
    } else {
	lappend display_list "<a href=\"task-file-new.tcl?task_id=$task_id&task_type=exam&[export_url_vars return_url]\">upload associated file</a>"
    }
}

if {[ad_permission_p $db "" "" "Delete Tasks" $user_id $class_id]} { 
    lappend display_list "<a href=\"task-delete.tcl?task_id=$task_id&task_type=exam\">delete $exam_name</a>"
}

if {$user_has_edit_permission_p} {
    if {![empty_string_p $sol_url]} {
	lappend display_list "<a href=\"$sol_url\">Solutions</a>"
    } elseif {![empty_string_p $sol_version_id]} {
	lappend display_list "<a href=\"/file-storage/download/$exam_name-solutions.$sol_file_extension?version_id=$sol_version_id\">solutions</a>"
    }     

    if {![empty_string_p $sol_file_id]} {
	lappend display_list "<a href=\"solutions-add-edit.tcl?[export_url_vars return_url task_id task_type]\">upload new solutions</a>"
    } else {
	lappend display_list "<a href=\"solutions-add-edit.tcl?[export_url_vars return_url task_id task_type]\">upload solutions</a>"
    }
}

append return_string "

[join $display_list " | "]

<p><br>
<h3>The following students have not been evaluated for $exam_name</h3>
<ul>
"

# get the list of students

# we outer join here with files so that we can display the student name
# whether or not the student has uploaded answers

set selection [ns_db select $db "select distinct users.user_id as student_id, 
                first_names, 
                last_name,
                files.url,
                files.file_extension,
                files.version_id
           from users, 
                user_group_map map, 
                (select * from fs_versions_latest 
                 where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') files
          where map.user_id = users.user_id 
            and lower(map.role) = lower('[edu_get_student_role_string]') 
            and map.group_id = $class_id
            and users.user_id = files.author_id(+)
            and users.user_id not in (select student_id  
                           from edu_student_evaluations 
                          where task_id = $exam_id
                            and student_id = users.user_id
                            and class_id = map.group_id)"]

set student_count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<li><a href=\"users/student-evaluation-add-edit.tcl?task_id=$exam_id&student_id=$student_id&return_url=$return_url&evaluation_type=exam\">$last_name, $first_names</a> \n"
    if {![empty_string_p $url]} {
	append return_string "&nbsp (<a href=\"$url\">student answers</a>)"
    } elseif {![empty_string_p $version_id]} {
	append return_string "&nbsp (<a href=\"/file-storage/download/$exam_name.$file_extension?version_id=$version_id\">student answers</a>)"
    }

    incr student_count
}

if {$student_count == 0} {
    append return_string "There are no students left to be evaluated."
}




append return_string "
</ul>
<h3>The following students have been evaluated for $exam_name</h3>
<ul>
"


# get the list of students that have already been evaluated

set selection [ns_db select $db "select users.user_id as student_id, 
                first_names, 
                last_name,
                files.url,
                files.file_extension,
                files.version_id
           from users, 
                user_group_map map, 
                edu_student_evaluations evals,
                (select * from fs_versions_latest 
                 where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') files
          where map.user_id = users.user_id 
            and users.user_id = files.author_id(+)
            and lower(map.role) = '[edu_get_student_role_string]' 
            and evals.task_id = $exam_id
            and evals.student_id = users.user_id
            and class_id = map.group_id
            and map.group_id = $class_id"]


set student_count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<li><a href=\"student-info.tcl?student_id=$student_id\">$last_name, $first_names</a> \n"
    incr student_count

    if {![empty_string_p $url]} {
	append return_string "&nbsp (<a href=\"$url\">student answers</a>)"
    } elseif {![empty_string_p $version_id]} {
	append return_string "&nbsp (<a href=\"/file-storage/download/$exam_name.$file_extension?version_id=$version_id\">student answers</a>)"
    }
}


if {$student_count == 0} {
    append return_string "No students have been evaluated."
}


append return_string "
</ul>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string








