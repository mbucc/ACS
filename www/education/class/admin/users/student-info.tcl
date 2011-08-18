#
# /www/education/class/admin/users/student-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows the admin to see pretty much all of the
# information relating to a student.

ad_page_variables {
    student_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set selection [ns_db select $db "select first_names, 
         last_name, 
         email as student_email,
         url as student_url, 
         map.role,
         portrait,
         portrait_thumbnail,
         pretty_role,
         pretty_role_plural
    from users, 
         user_group_map map,
         edu_role_pretty_role_map role_map
   where users.user_id = $student_id 
     and users.user_id = map.user_id 
     and role_map.group_id = map.group_id
     and lower(role_map.role) = lower(map.role)
     and map.group_id=$class_id"]


set count 0
set role_list [list]
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append role_list [string tolower $role]
    incr count
}

if {$count == 0} {
    ad_return_complaint 1 "<li>You must call this page with a valid user id that is a member of $class_name"
    return
}

if {[lsearch $role_list [string tolower [edu_get_student_role_string]]] == -1 && [lsearch $role_list [string tolower [edu_get_dropped_role_string]]] == -1} {
    ad_returnredirect "one.tcl?user_id=$student_id"
    return
}


set teams_p [database_to_tcl_string $db "select teams_p from edu_classes where class_id = $class_id"]

set institution_id [database_to_tcl_string_or_null $db "select field_value from user_group_member_field_map where user_id = $student_id and group_id = $class_id and field_name = 'Institution ID'"]

set student_account [database_to_tcl_string_or_null $db "select field_value from user_group_member_field_map where user_id = $student_id and group_id = $class_id and field_name = 'Student Account'"]


set assignment_info [list]
set team_info [list]
set eval_info [list]


# we want to list all of the assignments.  If there is a student file
# associated with the file (the student's answers) then we want to give 
# a link to that.  Finally, if there is an evaluation, we want to display
# it inline.  We need to do outerjoins to make sure that we display 
# all of the assignments even if evaluations have not yet been completed.


set selection [ns_db select $db "
select a.assignment_name, 
       first_names || ' ' || last_name as grader_name,
       answers.grader_id,
       answers.grade, 
       answers.comments, 
       answers.evaluation_id,
       answers.show_student_p,
       files.url,
       files.file_extension,
       files.version_id,
       a.assignment_id
  from edu_assignments a, 
       (select distinct version_id, url, file_extension, task_id
          from edu_student_answers ans, 
               fs_versions_latest ver
         where student_id = $student_id
           and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
           and ver.file_id = ans.file_id) files,
       (select users.first_names,
               users.last_name,
               eval.grade,
               eval.comments,
               eval.evaluation_id,
               eval.show_student_p,
               eval.task_id,
               eval.grader_id
          from edu_student_evaluations eval,
               users
         where users.user_id = eval.grader_id
           and eval.student_id = $student_id) answers
 where a.class_id = $class_id
   and a.assignment_id = files.task_id(+)
   and a.assignment_id = answers.task_id(+)
"]


set assignment_info ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    set answers_string ""

    if {![empty_string_p $url]} {
	set answers_string "<li><a href=\"$url\">$pretty_role Answers</a>"
    } elseif {![empty_string_p $version_id]} {
	set answers_string "<li><a href=\"/file-storage/download/$assignment_name.$file_extension?version_id=$version_id\">$pretty_role Answers</a>"
    }

    append assignment_info "
    <li><a href=\"../assignment-info.tcl?assignment_id=$assignment_id\"><b>$assignment_name</b></a>"

    if {[empty_string_p $evaluation_id]} {
	append assignment_info "&nbsp &nbsp (<a href=\"student-evaluation-add-edit.tcl?student_id=$student_id&task_id=$assignment_id&evaluation_type=assignment\">evaluate</a>)
	"

	if {![empty_string_p $answers_string]} {
	    append assignment_info "
	    $answers_string
	    "
	}

	append assignment_info "
	<ul>
	<li>No Evaluation
	</ul>
	<br>
	"
    } else {	
	append assignment_info "&nbsp &nbsp (<a href=\"student-evaluation-add-edit.tcl?evaluation_id=$evaluation_id\">edit this evaluation</a>)
	<ul>
	"

	if {![empty_string_p $answers_string]} {
	    append assignment_info "
	    $answers_string
	    "
	}

	append assignment_info "
	<li>
	Grade:
	[edu_maybe_display_text $grade]
	</li>
	
	<li>
	Comments:
	[edu_maybe_display_text $comments]
	</li>
	
	<li>
	Graded By:
	<a href=\"one.tcl?user_id=$grader_id\">$grader_name</a>
	</li>
	
	<li>
	Show Evalution to $pretty_role:
	[ad_html_pretty_boolean $show_student_p]
	</li>
	</ul>
	<br>
	"
    }
}


# now get the team information is there are teams for this class

if {[string compare $teams_p t] == 0} {
    set teams_info [database_to_tcl_list_list $db "select distinct team_id,
       team_name
  from edu_teams team, 
       user_group_map map
 where team.class_id = $class_id
   and team.team_id = map.group_id
   and map.user_id = $student_id"]
}



# now get the evaluations (excluding assignments) for the student

set eval_info [database_to_tcl_list_list $db "
select se.grader_id,
first_names || ' ' || last_name as grader_name,
evaluation_type,
grade,
comments,
evaluation_date,
evaluation_id
from edu_student_evaluations se,
users
where se.student_id=$student_id
and users.user_id = se.grader_id
and task_id is null
and se.class_id=$class_id"]


set return_string "
[ad_header "$pretty_role Info @ [ad_system_name]"]
<h2>$first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "students-view.tcl?view_type=all" "$pretty_role_plural"] "One $pretty_role"]

<hr>
<blockquote>

<table>
<tr>
<td>
<h3>Information
"

if {[lsearch $role_list [string tolower [edu_get_dropped_role_string]]] != -1} {
    append return_string "[ad_space 2] <font color=red>Dropped</font>"
}

append return_string "
</h3>
<ul>ID: $institution_id
<br>Account: $student_account
<br>Email: $student_email
<br>URL: 
"

if {![empty_string_p $student_url]} {
    append return_string "<a href=\"$student_url\">$student_url</a>"
} else {
    append return_string "None"
}

append return_string "
<br>
(<a href=\"student-info-edit.tcl?student_id=$student_id\">edit</a>)
</ul>
</td>
<td>
"

if {![empty_string_p $portrait_thumbnail]} {
    append return_string "
    <a href=\"/shared/portrait.tcl?user_id=$student_id\"><img width=125 src=\"/shared/portrait-thumbnail-bits.tcl?user_id=$student_id\"></a>"
} elseif {![empty_string_p $portrait]} {
    append return_string "
    <a href=\"/shared/portrait.tcl?user_id=$student_id\"><img width=125 src=\"/shared/portrait-bits.tcl?user_id=$student_id\"></a>"
}

append return_string "
</td>
</tr>
</table>

<h3>Assignments</h3>
<ul>
"

if {![empty_string_p $assignment_info]} {
    append return_string "
    $assignment_info
    "
} else {
    append return_string "
    No assignment info available"
}

set count 0

append return_string "
</ul>
<h3>$pretty_role Evaluations</h3>
<ul>
"

foreach evaluation $eval_info {
    if {$count} {
	append return_string "<p>"
    }

    append return_string "
    <table cellpadding=2>
    <tr>
    <th align=right>Evaluation Type</th>
    <td>[lindex $evaluation 2]</td>
    </tr>
    <tr>
    <th align=right>Grade</th>
    <td>[lindex $evaluation 3]</td>
    </tr>
    <tr>
    <th align=right>Comments</th>
    <td>[lindex $evaluation 4]</td>
    </tr>
    <tr>
    <th align=right>Grader</th>
    <td><a href=\"one.tcl?user_id=[lindex $evaluation 0]\">[lindex $evaluation 1]</a></td>
    </tr>
    <tr>
    <th align=right>Date</th>
    <td>[util_AnsiDatetoPrettyDate [lindex $evaluation 5]]</td>
    </tr>
    <tr><th></th>
    <td><a href=student-evaluation-add-edit.tcl?evaluation_id=[lindex $evaluation 6]>Edit</a></td></tr>
    </table>"
    
    incr count
}

if {!$count} {
    append return_string "
    No evaluation info available"
}

append return_string "<p><a href=\"student-evaluation-add-edit.tcl?student_id=$student_id\">Add an evaluation</a></p>"

if {[string compare $teams_p t] == 0} {
    
    set team_count 0
    
    append return_string "
    </ul>
    <h3>$pretty_role Teams</h3>
    <ul>
    "
    
    if {![empty_string_p $teams_info]} {
	foreach team $teams_info {
	    append return_string "
	    <li><a href=\"../teams/one.tcl?team_id=[lindex $team 0]\">[lindex $team 1]</a>"
	}
    } else {
	append return_string "
	No team info available"
    }


    set return_url "[ns_conn url]?[ns_conn query]"

    # lets see if we should let them choose from existing teams or if they should
    # be given the create a team page.
    
    if {[database_to_tcl_string $db "select count(team_id) from edu_teams where class_id = $class_id"] > $team_count} {
	append return_string "
	<p><a href=\"student-assign-to-team.tcl?[export_url_vars return_url student_id]\">Assign $first_names to a team</a>
	"
    } else {
	append return_string "
	<br><a href=\"../teams/create.tcl?[export_url_vars return_url student_id]\">Assign $first_names to a team</a>
	"
    }
}


set return_url "student-info.tcl?student_id=$student_id"

set return_url [export_url_vars return_url]

append return_string "
</ul>
<br>
  <li><a href=\"role-change.tcl?user_id=$student_id&$return_url\">Edit user's roles</a></li>
  <li><a href=\"password-update.tcl?user_id=$student_id&$return_url\">Update $pretty_role's password</a></li>
  <li><a href=\"delete.tcl?user_id=$student_id&$return_url\">Remove $pretty_role</a></li>
</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string






