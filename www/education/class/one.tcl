#
# /www/education/class/one.tcl (as in one class)
#
# by randyg@arsdigita.com, aileen@arsdigita.com, January 2000
#
# this displays information about one class
#

set db [ns_db gethandle]

set id_list [edu_user_security_check $db]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]

set selection [ns_db 0or1row $db "select 
               class_name,
               term_id,
               c.subject_id,
               start_date,
               end_date,
               nvl(c.description, s.description) as description,
               where_and_when,
               syllabus_id,
               version_id,
               file_extension,
               lecture_notes_folder_id,
               handouts_folder_id,
               assignments_folder_id,
               public_p,
               grades_p,
               teams_p,
               exams_p,
               final_exam_p,
               credit_hours, 
               prerequisites
          from edu_current_classes c,
               (select * from fs_versions_latest 
                where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') ver,
               edu_subjects s
         where class_id = $class_id
           and syllabus_id = file_id(+)
           and c.subject_id = s.subject_id(+)"]


if {$selection == ""} {
    ad_return_complaint 1 "<li> The class you have requested either does not exist or is not longer available to the public."
    return
} else {
    set_variables_after_query
}

set header "

[ad_header "Classes @ [ad_system_name]"]

<h2>$class_name</h2>

[ad_context_bar_ws [list "" Classes] "One Class"]

<hr>

<blockquote>
"


set class_info_text "
<table>
<tr>
<th valign=top align=left>
Description:
</td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>
"

if {![empty_string_p $credit_hours]} {
    append class_info_text "
    <tr>
    <th valign=top align=left>
    Credit Hours:
    </td>
    <td valign=top>
    $credit_hours
    </td>
    </tr>
    "
}

if {![empty_string_p $prerequisites]} {
    append class_info_text "
    <tr>
    <th valign=top align=left>
    Prerequisites:
    </td>
    <td valign=top>
    $prerequisites
    </td>
    </tr>
    "
}

append class_info_text "</table>"


#
#
# get information about the instructors
#
#



# get all instructors and things like their office hours (in field_values)
set selection [ns_db select $db "select distinct fm.sort_key,
          role_map.role,
          role_map.sort_key,
          pretty_role,
          pretty_role_plural,
          first_names || ' ' || last_name as user_name,
          users.user_id, 
          email,
          url,
          fm.field_name, 
          fm.field_value
     from users,
          user_group_map map,
          edu_role_pretty_role_map role_map,
          (select distinct fm.field_name, 
                   fm.field_value,
                   tmf.sort_key,
                   fm.user_id
              from user_group_type_member_fields tmf,
                   user_group_member_field_map fm,
                   user_group_map map
             where group_type = 'edu_class'
               and fm.group_id = $class_id
               and map.user_id = $user_id
               and map.group_id = fm.group_id
               and (tmf.role is null or lower(tmf.role) = lower(map.role))
               and lower(tmf.field_name) = lower(fm.field_name)
               order by sort_key) fm
     where users.user_id = map.user_id
       and (lower(map.role) = lower('[edu_get_professor_role_string]') 
            or lower(map.role) = lower('[edu_get_ta_role_string]'))
       and map.group_id = $class_id
       and map.user_id=fm.user_id(+)
       and lower(role_map.role) = lower(map.role)
       and role_map.group_id = map.group_id
  order by role_map.sort_key, role_map.role, user_name, fm.sort_key"]


# we use old_user_id here because the above query can potentially
# return more than one row for each user.  For instance, for a prof,
# it will return one row for the office location, phone number, and
# office hours.  Since we only want to display the name once, we only
# add the text once.

set teacher_text ""
set old_user_id ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    if {$old_user_id!=$user_id} {
	if {$old_user_id!=""} {
	    append teacher_text "</ul>"
	}
	
	if {![empty_string_p $url]} {
	    set user_name "<a href=\"$url\">$user_name</a>"
	}
	append teacher_text "<li>$pretty_role - $user_name (<a href=mailto:$email>$email</a>) \n"
	set old_user_id $user_id
	append teacher_text "<ul>"
    }

    append teacher_text "<li><b>$field_name</b>: [edu_maybe_display_text $field_value] \n"
}

if {![empty_string_p $teacher_text]} {
    set course_staff_text "
    <h3>Course Staff</h3>
    <ul>
    $teacher_text
    </ul>
    </ul>
    "
} else {
    set course_staff_text ""
}


# if there is a syllabus, show a link here

if {![empty_string_p $syllabus_id]} {
    set syllabus_text "<a href=\"/file-storage/download/Syllabus.$file_extension?version_id=$version_id\">Syllabus</a>"
} else {
    set syllabus_text ""
}


set selection [ns_db select $db "select title, 
                              edu_textbooks.textbook_id 
                         from edu_textbooks, 
                              edu_classes_to_textbooks_map map 
                        where edu_textbooks.textbook_id = map.textbook_id 
                          and map.class_id = $class_id 
                        order by title"]

set textbook_text ""

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append textbook_text "<li><a href=\"textbook-info.tcl?textbook_id=$textbook_id\">$title</a> \n"
}


if {![empty_string_p $textbook_text]} {
    textbook_text_to_show "
    <h3>Textbooks</h3>
    <ul>
    $textbook_text
    </ul>
    "
} else {
    set textbook_text_to_show ""
}

#################################
#                               #
#  Begin displaying assignments #
#                               #
#################################


set assignment_text "
<h3>Assignments</h3>
<ul>
"
set user_has_turn_in_permission_p [ad_permission_p $db "" "" "Submit Tasks" $user_id $class_id]

# get all of the assignments.  If there are solutions, get those.
# if the student has uploaded their answers, get those as well

set selection [ns_db select $db "select edu_assignments.assignment_name, 
            edu_assignments.assignment_id, 
            edu_assignments.due_date, 
            pset.version_id, 
            pset.file_extension,
            pset.url,
            sol.url as sol_url,
            sol.file_extension as sol_file_extension,
            sol.version_id as sol_version_id,
            answers.url as ans_url,
            answers.file_extension as ans_file_extension,
            answers.file_title as ans_filename,
            answers.version_id as ans_version_id,
            edu_assignments.electronic_submission_p
       from edu_assignments,
            edu_assignments edu_assignments1,
            (select * from fs_versions_latest 
              where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') pset,
            (select file_extension, url, version_id, task_id 
                    from fs_versions_latest ver,
                         edu_task_solutions solutions
                   where ver.file_id = solutions.file_id
                     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') sol,
            (select file_extension, file_title, url, version_id, task_id
                    from fs_versions_latest ver,
                         edu_student_answers ans,
                         fs_files
                   where ver.file_id = ans.file_id 
                     and fs_files.file_id = ver.file_id
                     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
                     and student_id = $user_id) answers
      where edu_assignments.class_id = $class_id 
        and edu_assignments.file_id = pset.file_id(+)
        and edu_assignments1.assignment_id = edu_assignments.assignment_id
        and edu_assignments1.assignment_id = answers.task_id(+)
        and edu_assignments.assignment_id = sol.task_id(+)
     order by due_date"]


set count 0
set assignment_info "<table>"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count

    if {![empty_string_p $url]} {
	append assignment_info "<tr><td><a href=\"$url\">$assignment_name</a></td>"
    } elseif {![empty_string_p $version_id]} {
	append assignment_info "<tr><td><a href=\"/file-storage/download/[join $assignment_name "_"].$file_extension?version_id=$version_id\">$assignment_name</a></td>"
    } else {
	append assignment_info "<td>$assignment_name</td>"
    }
    
    append assignment_info "
    <td><a href=\"assignment-info.tcl?assignment_id=$assignment_id\">Details</a></td>
    "


    set submit_solutions_text "Submit Solutions"

    if {[string compare $electronic_submission_p t] == 0} {
	set submit_solutions_text "Submit/Update Answers"

	if {![empty_string_p $ans_url]} {
	    append assignment_info "<td><a href=\"$ans_url\">Your Answers</a></td>"
	} elseif {![empty_string_p $ans_version_id]} {
	    append assignment_info "<td><a href=\"/file-storage/download/$ans_filename.$ans_file_extension?version_id=$ans_version_id\">Your Answers</a></td>"
	} else {
 	    append assignment_info "<td>[ad_space]</td>"
	}
    } else {
	append assignment_info "<td>[ad_space]</td>"
    }

    if {[empty_string_p $sol_url] && [empty_string_p $sol_version_id]} {
	append assignment_info "<td>Due: [util_AnsiDatetoPrettyDate $due_date]</td> \n"
	if {[string compare $electronic_submission_p t] == 0 && $user_has_turn_in_permission_p} {
	    append assignment_info "<td><a href=\"task-turn-in.tcl?task_id=$assignment_id&task_type=assignment\">$submit_solutions_text</a></td>"
	} else {
	    append assignment_info "<td>[ad_space]</td>"
	}
    } elseif {![empty_string_p $sol_url]} {
	append assignment_info "<Td colspan=2 align=left><a href=\"$sol_url\">Solutions</a></td>"
    } elseif {![empty_string_p $sol_version_id]} {
	append assignment_info "<td colspan=2 align=left><a href=\"/file-storage/download/$assignment_name-solutions.$sol_file_extension?version_id=$sol_version_id\">Solutions</a></td>"
    } 
    append assignment_info "</tr>"
}

if {$count == 0} {
    append assignment_text "None"
} else {
    append assignment_text "$assignment_info </table>"
}

append assignment_text "</ul>"





#
#
#  Begin the code to generate lecture notes
#
#



set lecture_notes_text "
<h3>Lecture Notes</h3>
<ul>
"
# we join with fs_versions_latest to make sure that
# they have permission to view the handout

set selection [ns_db select $db "select handout_id, 
         edu_handouts.file_id, 
         distribution_date, 
         handout_name
    from edu_handouts,
         fs_versions_latest ver
   where lower(handout_type) = lower('lecture_notes') 
     and class_id = $class_id 
     and ver.file_id = edu_handouts.file_id
     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
order by distribution_date"]


set lecture_notes_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr lecture_notes_count

    if {![empty_string_p $url]} {
	append lecture_notes_text "<tr><td> <a href=\"$url\">$handout_name</a>"
    } elseif {![empty_string_p $version_id]} {
	append lecture_notes_text "<tr><td> <a href=\"/file-storage/download/[join $handout_name "_"].$file_extension?version_id=$version_id\">$handout_name</a>"
    } else {
	append lecture_notes_text "<tr><td> $handout_name"
    }
    
    append lecture_notes_text "
    <td>Distributed: 
    [util_AnsiDatetoPrettyDate $distribution_date]
    </td></tr>"
}

if {$lecture_notes_count == 0} {
    append lecture_notes_text "<tr><td>There are currently no lecture notes.</td></tr>"
}

append lecture_notes_text "</table></ul>"


#
#
#  Begin the code to generate Handouts
#
#



set handouts_text "
<h3>Handouts</h3>
<ul>
<table>
"

set selection [ns_db select $db "select version_id, 
         edu_handouts.file_id, 
         distribution_date, 
         handout_name
    from edu_handouts,
         fs_versions_latest ver
   where lower(handout_type) = lower('general') 
     and ver.file_id = edu_handouts.file_id
     and class_id = $class_id 
     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't'
order by distribution_date"]

set handouts_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr handouts_count

    if {![empty_string_p $url]} {
	append handouts_text "<tr><td> <a href=\"$url\">$handout_name</a>"
    } elseif {![empty_string_p $version_id]} {
	append handouts_text "<tr><td> <a href=\"/file-storage/download/[join $handout_name "_"].$file_extension?version_id=$version_id\">$handout_name</a>"
    } else {
	append handouts_text "<tr><td> $handout_name"
    }
    
    append handouts_text "
    <td>Distributed: 
    [util_AnsiDatetoPrettyDate $distribution_date]
    </td></tr>"
}

if {$handouts_count == 0} {
    append handouts_text "<tr><td>There are currently no handouts.</td></tr>"
}

append handouts_text "</table></ul>"



#################################
#                               #
#  Begin displaying exams       #
#                               #
#################################


if {[string compare $exams_p t] == 0} {

    set selection [ns_db select $db "select exam_name, 
             e.exam_id,
             ver.version_id,
             ver.file_extension,
             ver.url,
             ver.file_id,
             sol.version_id as sol_version_id,
             sol.file_extension as sol_file_extension,
             sol.url as sol_url,
             sol.file_id as sol_file_id
        from edu_exams e,
             (select * from fs_versions_latest 
              where ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') ver,
             (select file_extension, url, version_id, task_id, ver.file_id 
                    from fs_versions_latest ver,
                         edu_task_solutions solutions
                   where ver.file_id = solutions.file_id
                     and ad_general_permissions.user_has_row_permission_p($user_id, 'read', version_id, 'FS_VERSIONS') = 't') sol
    where e.class_id = $class_id
    and e.exam_id = sol.task_id(+)
    and e.file_id = ver.file_id(+)"]
    
    set n_exams 0

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	
	if {!$n_exams} {
	    set exam_text "
	    <h3>Exams</h3>
	    <ul>
	    <table>"
	}

	if {![empty_string_p $sol_url]} {
	    append exam_text "<tr><Td><a href=\"$sol_url\">solutions</a></td>"
	} elseif {![empty_string_p $version_id]} {
	    append exam_text "
	    <tr><td><a href=\"/file-storage/download/$exam_name.$file_extension?version_id=$version_id\">$exam_name</a></td>"
	} else {
	    append exam_text "<tr><td>$exam_name</a></td>\n"
	}

	append exam_text "<td><a href=\"exam-info.tcl?exam_id=$exam_id\">Details</a></td>\n"
	
	if {[empty_string_p $sol_url] && ![empty_string_p $sol_version_id]} {
	    # there are already solutions - a file in the file system
	    append exam_text "
	    <td><a href=\"/file-storage/download/$exam_name.$sol_file_extension?version_id=$sol_version_id\">solutions</a></td>"
	} elseif {![empty_string_p $sol_url]} {
	    # there are already solutions - a url
	    append exam_text "<td><a href=\"$sol_url\">Solutions</a></td>"
	} else {
	    append exam_text "<td>[ad_space]</td>"
	}
	incr n_exams
    }

    if {$n_exams > 0} {
	append exam_text "</table></ul>"
    } else {
	set exam_text ""
    }

    
} else {
    set exam_text ""
}


#################################
#                               #
#  Begin displaying projects    #
#                               #
#################################


set projects_string ""
set n_projects 0
set selection [ns_db select $db "select project_name,
       project_id
from edu_projects
where class_id = $class_id"]
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr n_projects
    append projects_string "<li><a href=\"projects/one.tcl?[export_url_vars project_id]\">$project_name</a>\n"
}

if $n_projects {
    set project_text "
    <h3>Projects</h3>
    <ul>
    $projects_string
    </ul>"
} else {
    set project_text ""
}


#################################
#                               #
#  Begin displaying teams       #
#                               #
#################################


if {[string compare $teams_p t] == 0} {
    set teams_string ""
    
    set n_teams [database_to_tcl_string $db "select count(team_id) from edu_teams where class_id = $class_id"]
set user_id 0
    if {![string compare $user_id 0] == 0} {
	set selection [ns_db select $db "select team_name, team_id, project_name, project_description, project_url from edu_teams, user_group_map map where class_id = $class_id and map.user_id = $user_id and map.group_id = edu_teams.class_id"]
	
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    incr n_teams -1
	    if {$n_teams > 1} {
		append teams_string "<br><br>"
	    }
	    append teams_string "
	    <li>Team Name: <a href=\"team-info.tcl?team_id=$team_id\">$team_name</a>
	    <li>Project Name: $project_name 
	    <li>Project Description: $project_description 
	    <li>Project URL: [edu_maybe_display_text "<a href=\"$project_url\">$project_url</a>"]
	    "
	}

	if {$n_teams > 0} {
	    # lets provide a link to view the rest of the teams
	    append teams_string "<br><br>
	    <a href=\"teams-view.tcl?class_id=$class_id\">View All Teams</a> - fix this so that this only shows up if all of the teams have not already been displayed.
	    "
	}
    } else {
	
	# the user is not logged in or is not a member of any team 
	# so list all of the teams by name

	set selection [ns_db select $db "select team_name, team_id from edu_teams where class_id = $class_id"]

	set n_teams 0
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    incr n_teams
	    append teams_string "
	    <li><a href=\"team-info.tcl?team_id=$team_id\">$team_name</a>\n"
	}
    }

    if {![empty_string_p $teams_string]} {
	set teams_text "
	<h3>Teams</h3>
	<ul>
	$teams_string
	</ul>
	"
    } else {
	set teams_text ""
    }
} else {
    set teams_text ""
}


#################################
#                               #
#  Begin displaying news        #
#                               #
#################################


set news_string ""

set query "select news_item_id, title, release_date
from news_items, newsgroups
where newsgroups.newsgroup_id = news_items.newsgroup_id
and sysdate between release_date and expiration_date
and approval_state = 'approved'
and group_id = $class_id
and scope = 'group'
order by release_date desc, creation_date desc"

set selection [ns_db select $db $query]

set counter 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append news_string "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"/news/item.tcl?news_item_id=$news_item_id\">$title</a>\n"
    incr counter 
}

if { $counter > 0 } {
    set news_text "
    <h3>News</h3>
    <ul>$news_string</ul>"
} else {
    set news_text ""
}


################################################
#                                              #
#  Begin displaying collaboration items        #
#                                              #
################################################

set chat_room_id [database_to_tcl_string_or_null $db "select chat_room_id from chat_rooms where group_id=$class_id"]

# select the bboard topic that is accessible to students in the class
# set bboard_cnt [database_to_tcl_string $db "
# select count(*) 
# from bboard_topics t,
#      edu_role_pretty_role_map m1, edu_role_pretty_role_map m2 
# where t.group_id=$class_id 
# and t.role=m1.role
# and m1.priority>=m2.priority
# and m2.role='student'"]

# if {$bboard_cnt>0} {
#     set bboard_info "<li><a href=/bboard/index.tcl?group_id=$class_id>Q&A Forum</a>"
#} else {
    set bboard_info ""
#}


if {![empty_string_p $bboard_info] && ![empty_string_p $chat_room_id]} {
    set collaboration_text "
    <h3>Collaboration</h3>
    <ul>
    $bboard_info
    [ec_decode $chat_room_id "" "" "<li><a href=/chat/enter-room.tcl?chat_room_id=$chat_room_id>Chat Room</a>"]
    </ul>
    "
} else {
    set collaboration_text ""
}

set selection [ns_db select $db "
select grade_name, weight, grade_id
from edu_grades where class_id=$class_id"]
set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if {$count == 0} {
	set grades_text "
	<h3>Grade Distribution</h3>
	<ul>"
    }
    append grades_text "
    <li>$grade_name - $weight\%"
    incr count
}    

if {!$count} {
    set grades_text ""
} else {
    append grades_text "</ul>"
}





ns_db releasehandle $db

ns_return 200 text/html "
$header
$news_text
$class_info_text
$course_staff_text
$syllabus_text
$textbook_text_to_show
$assignment_text
$lecture_notes_text
$handouts_text
$exam_text
$grades_text
$project_text
$teams_text
$collaboration_text
</blockquote>
[ad_footer]
"