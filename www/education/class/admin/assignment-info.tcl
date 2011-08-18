#
# /www/education/class/admin/assignment-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page shows information for a given assignment
#

ad_page_variables {
    assignment_id
}


set db [ns_db gethandle]


# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "View Admin Pages"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set return_url "[edu_url]class/admin/assignment-info.tcl?assignment_id=$assignment_id"



# make sure that the person is logged in under the correct class.  If not,
# tell them and give them the option to log in as the correct class if
# applicable

set assignment_class_id [database_to_tcl_string $db "select class_id from edu_assignments where assignment_id = $assignment_id"]

if {[string compare $assignment_class_id $class_id] != 0} {
    # lets see if the person has permission to view this assignment
    # (Are they a member of the class that the assignment belongs to)

    set class_member_p [database_to_tcl_string_or_null $db "select 1 from edu_classes, user_group_map where edu_classes.class_id = $assignment_class_id and user_group_map.group_id = edu_classes.class_id and user_group_map.user_id = $user_id"]

    if {$class_member_p == 0} {
	edu_display_not_authorized_message
    } else {
	# they are a member of the group so lets give them the option
	# to log in as that group
	ns_db releasehandle $db
	ns_return 200 text/html "
	[ad_header "Authorization Failed"]
	<h3>Authorization Failed</h3>
	in <a href=/>[ad_system_name]</a>
	<hr>
	<blockquote>
	The assignment you have chosen does not belong to this class.
If you would like to view this assignment, click <a
href=\"/education/util/group-login.tcl?group_id=$assignment_class_id&group_type=edu_class&return_url=[ns_urlencode $return_url]\">here</a>
to log in as a member of the correct class.
	</blockquote>
	[ad_footer]
    "
    }
    return
}


set selection [ns_db 0or1row $db "select
             ea.class_id, 
             assignment_id,
             ea.assignment_name,
             class_name,
             teacher_id,
             first_names,
             last_name,
             ea.description,
             ea.date_assigned,
             last_modified,
             due_date,
             grade_id,
             weight,
             electronic_submission_p,
             requires_grade_p,
             ver.version_id, 
             ver.file_extension,
             ver.url,
             ver.file_id,
             sol.file_id as sol_file_id,
             sol.version_id as sol_version_id,
             sol.url as sol_url,
             sol.file_extension as sol_file_extension,
             decode(sign(sysdate-due_date),1,1,0) as past_due_p
        from edu_assignments ea,
             users,
             edu_classes ec,
             (select * from fs_versions_latest 
              where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') ver,
             (select sol.file_id, version_id, file_extension, url, task_id
              from edu_task_solutions sol, 
                   fs_versions_latest ver
              where task_id = $assignment_id
                and sol.file_id = ver.file_id
                and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') sol
       where ec.class_id = ea.class_id
         and users.user_id = ea.teacher_id
         and ea.assignment_id = $assignment_id
         and ec.class_id = $class_id
         and ea.file_id = sol.file_id(+)
         and ea.file_id = ver.file_id(+)"]


if {$selection == ""} {
    ad_return_complaint 1 "There are no assignments corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
    return
} else {
    set_variables_after_query
}
    


set return_string "
[ad_header "One Assignment @ [ad_system_name]"]

<h2>$assignment_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" Administration] "One Assignment"]

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
<br>
"

# we have several things that we want to display here
# and what is displayed depends on several conditions
# if the Assignment is not yet due:
# 1. Edit Assignment
# 2. Upload a new version of the assignment
# 3. Delete the assignment
# and we always want to show
# 4. Upload solutions/new version of solutions
# 5. if there are solutions, a link to them

set task_type assignment
set task_id $assignment_id

set user_has_edit_permission_p [ad_permission_p $db "" "" "Edit Tasks" $user_id $class_id]

set edit_list [list]

if {$user_has_edit_permission_p && !$past_due_p} {
    lappend edit_list "<a href=\"task-edit.tcl?task_id=$assignment_id&task_type=$task_type&return_url=[ns_urlencode $return_url]\">edit</a>"
    if {![empty_string_p $file_id]} {
	lappend edit_list "<a href=\"task-file-new.tcl?[export_url_vars return_url task_id task_type]\">upload new file</a>"
    } else {
	lappend edit_list "<a href=\"task-file-new.tcl?[export_url_vars return_url task_id task_type]\">upload associated file</a>"
    }
}

if {[ad_permission_p $db "" "" "Delete Tasks" $user_id $class_id] && !$past_due_p} { 
    lappend edit_list "<a href=\"task-delete.tcl?task_id=$assignment_id&task_type=$task_type\">delete $assignment_name</a>"
}

if {$user_has_edit_permission_p} {
    if {![empty_string_p $sol_url]} {
	lappend edit_list "<a href=\"$sol_url\">Solutions</a>"
    } elseif {![empty_string_p $sol_version_id]} {
	lappend edit_list "<a href=\"/file-storage/download/$assignment_name-solutions.$sol_file_extension?version_id=$sol_version_id\">solutions</a>"
    }     

    if {![empty_string_p $sol_file_id]} {
	lappend edit_list "<a href=\"solutions-add-edit.tcl?[export_url_vars return_url task_id task_type]\">upload new solutions</a>"
    } else {
	lappend edit_list "<a href=\"solutions-add-edit.tcl?[export_url_vars return_url task_id task_type]\">upload solutions</a>"
    }
}


##############################################
#                                            #
#  We are now going to list the students     #
#  that have and have not been evaluated for #
#  the given assignment                      #
#                                            #
##############################################



append return_string "
[join $edit_list " | "]
</form>
<p><br>
<h3>The following students have not been evaluated for $assignment_name</h3>
<ul>
"

# get the list of students

# we outer join here with files so that we can display the student name
# whether or not the student has uploaded answers

set selection [ns_db select $db "select users.user_id as student_id, 
                first_names, 
                last_name,
                files.url,
                files.file_extension,
                files.version_id
           from users, 
                user_group_map map, 
                (select url, author_id as student_id,
                        file_extension, version_id 
                      from fs_versions_latest ver, 
                           edu_student_answers task  
                     where task_id = $assignment_id 
                       and task.file_id = ver.file_id
                       and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') files 
          where map.user_id = users.user_id 
            and lower(map.role) = lower('[edu_get_student_role_string]') 
            and map.group_id = $class_id
            and users.user_id = files.student_id(+)
            and users.user_id not in (select student_id  
                           from edu_student_evaluations 
                          where task_id = $assignment_id
                            and student_id = users.user_id
                            and map.group_id = $class_id)"]

set student_count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<li><a href=\"users/student-evaluation-add-edit.tcl?task_id=$assignment_id&student_id=$student_id&return_url=$return_url\">$last_name, $first_names</a> \n"
    if {![empty_string_p $url]} {
	append return_string "&nbsp (<a href=\"$url\">student answers</a>)"
    } elseif {![empty_string_p $version_id]} {
	append return_string "&nbsp (<a href=\"/file-storage/download/$assignment_name.$file_extension?version_id=$version_id\">student answers</a>)"
    }

    incr student_count
}

if {$student_count == 0} {
    append return_string "There are no students left to be evaluated."
}




append return_string "
</ul>
<h3>The following students have been evaluated for $assignment_name</h3>
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
                (select url, author_id as student_id,
                        file_extension, version_id 
                      from fs_versions_latest ver, 
                           edu_student_answers task  
                     where task_id = $assignment_id 
                       and task.file_id = ver.file_id
                       and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') files 
          where map.user_id = users.user_id 
            and lower(map.role) = lower('[edu_get_student_role_string]') 
            and evals.task_id = $assignment_id
            and evals.student_id = users.user_id
            and class_id = map.group_id
            and map.group_id = $class_id
            and map.user_id = files.student_id(+)"]



set student_count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<li><a href=\"users/student-info.tcl?student_id=$student_id\">$last_name, $first_names</a> \n"
    incr student_count

    if {![empty_string_p $url]} {
	append return_string "&nbsp (<a href=\"$url\">student answers</a>)"
    } elseif {![empty_string_p $version_id]} {
	append return_string "&nbsp (<a href=\"/file-storage/download/$assignment_name.$file_extension?version_id=$version_id\">student answers</a>)"
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








