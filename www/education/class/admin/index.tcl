#
# /www/education/class/admin/index.tcl
#
# this page is the index page for the class administrators
# 
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "View Admin Pages"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


# get properties for this class

set selection [ns_db 0or1row $db "select start_date,
	grades_p,
	teams_p,
	exams_p,
	final_exam_p
   from edu_classes
  where class_id = $class_id"]

if {$selection == ""} {
    ad_return_complaint 1 "<li>The class you have requested does not exist."
    return
} else {
    set_variables_after_query
}


set header "
[ad_header "$class_name Administration @ [ad_system_name]"]

<h2>$class_name Administration</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] "Administration"]

<hr>
<blockquote>
"

#  Begin the code to generate News

set news_text "
<h3>News</h3>
<ul>
"

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
    append news_text "<li>[util_AnsiDatetoPrettyDate $release_date]: <a href=\"/news/item.tcl?news_item_id=$news_item_id\">$title</a>\n"
    incr counter 
}

if {$counter == 0} {
    append news_text "<li>No items found."
}

append news_text "
<li><a href=/news/post-new.tcl?scope=group&group_id=$class_id>Add news item</a>
</ul>
"
# <li><a href=/news/index.tcl?scope=group&group_id=646&archive_p=1>News archive</a>


#
#  Begin the code to generate Class Resources


set class_resources "
<h3>Manage Class Resources</h3>
<ul>

<li> <a href=properties-edit.tcl>Edit Class Properties</a>
"


# Get the Syllabus Information

set selection [ns_db 0or1row $db "select version_id, 
                          file_extension,
                          file_id,
                          url
                     from fs_versions_latest, 
                          edu_classes 
                    where file_id = syllabus_id 
                      and class_id = $class_id"] 

if {$selection == ""} {
    append class_resources "<li> <a href=\"syllabus-edit.tcl\">Add a Syllabus</a>"
} else {
    set_variables_after_query
    if {![empty_string_p $url]} {
	append class_resources "<li> <a href=\"$url\">Syllabus</a>"
    } else {
	append class_resources "
	<li> <a href=\"/file-storage/download/syllabus.$file_extension?version_id=$version_id\">Syllabus</a>"
    } 

    append class_resources "[ad_space] | [ad_space] <a href=\"syllabus-edit.tcl\">upload new syllabus</a>"


}


set chat_room_id [database_to_tcl_string_or_null $db "
select chat_room_id from chat_rooms where scope='group' and group_id=$class_id"]

if {$chat_room_id!=""} {
    set chat_info "<a href=/chat/enter-room.tcl?chat_room_id=$chat_room_id>Chat Room</a>"
} else {
    set chat_info "<a href=\"[edu_url]util/chat-room-create.tcl\">Create new chat room</a>"
}

#set bboard_count [database_to_tcl_string $db "
#select count(*)  
#from bboard_topics t
#where t.group_id=$class_id"]

# <li> <a href=\"/file-storage/group.tcl?group_id=$class_id\">View Class Documents</a>
#<li> [ec_decode $bboard_count 0 "<a href=new-bboard-topic-add.tcl>Create new discussion board</a>" "<a href=/bboard/index.tcl?group_id=$class_id>Discussion Boards</a> | <a href=new-bboard-topic-add.tcl>Create new discussion board</a>"]

append class_resources "
<li> $chat_info
<li> <a href=\"permissions.tcl\">Permissions</a>
</ul>
"


#
#
#  Begin the code to generate assignments
#
#

set assignments_text "
<h3>Assignments</h3>
<ul>
"

set selection [ns_db select $db "select assignment_name, assignment_id from edu_assignments where class_id = $class_id order by due_date"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr count
    append assignments_text "<li><a href=\"assignment-info.tcl?assignment_id=$assignment_id\">$assignment_name</a> \n"

}

if {$count > 0} {
    append assignments_text "<p>"
}

append assignments_text "
<li> <a href=\"task-add.tcl?task_type=assignment\">Add an Assignment</a></li>
</ul>
"


#
#
#  Begin the code to generate lecture notes
#
#



set lecture_notes_text "
<h3>Lecture Notes</h3>
<ul>
"

set selection [ns_db select $db "select handout_id, 
         edu_handouts.file_id, 
         distribution_date, 
         handout_name
    from edu_handouts
   where lower(handout_type) = lower('lecture_notes') 
     and class_id = $class_id 
order by distribution_date"]

set lecture_notes_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr lecture_notes_count
    append lecture_notes_text "
    <li><a href=\"handouts/one.tcl?handout_id=$handout_id\">$handout_name</a>
    "
}

if {$lecture_notes_count > 0} {
    append lecture_notes_text "<p>"
} 

append lecture_notes_text "
<li><a href=\"handouts/add.tcl?type=lecture_notes\">Upload New Lecture Notes</a></ul>
"


#
#
#  Begin the code to generate Handouts
#
#



set handouts_text "
<h3>Handouts</h3>
<ul>
"

set selection [ns_db select $db "select handout_id, 
         edu_handouts.file_id, 
         distribution_date, 
         handout_name
    from edu_handouts
   where lower(handout_type) = lower('general') 
     and class_id = $class_id 
order by distribution_date"]

set handouts_count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr handouts_count
    append handouts_text "
    <li><a href=\"handouts/one.tcl?handout_id=$handout_id\">$handout_name</a>
    "
}

if {$handouts_count > 0} {
    append handouts_text "<p>"
} 

append handouts_text "
<li><a href=\"handouts/add.tcl?type=general\">Upload New Handout</a></ul>
"



#
#
#  Begin the code to generate user management stuff
#
#

set n_profs [database_to_tcl_string $db "select count(user_id) from user_group_map where group_id = $class_id and role = '[edu_get_professor_role_string]'"]

set n_tas [database_to_tcl_string $db "select count(user_id) from user_group_map where group_id = $class_id and role = '[edu_get_ta_role_string]'"]

set n_students [database_to_tcl_string $db "select count(user_id) from user_group_map where group_id = $class_id and role = '[edu_get_student_role_string]'"]

set n_dropped [database_to_tcl_string $db "select count(user_id) from user_group_map where group_id = $class_id and role = '[edu_get_dropped_role_string]'"]


set manage_users_text "
<h3>Manage <a href=\"users/\">Users</a></h3>
<ul>
<li> Total Students: <a href=\"users/students-view.tcl?view_type=all&target_url=[ns_urlencode "student-info.tcl"]\">[expr $n_students + $n_dropped]</a>"

if {$n_dropped == 1} {
    append manage_users_text "[ad_space] ($n_dropped has dropped)"
} elseif {$n_dropped > 1} {
    append manage_users_text "[ad_space] ($n_dropped have dropped)"
}

if {[string compare $teams_p t] == 0} {
    append manage_users_text "<li>Student Teams: <a href=\"teams/\">[database_to_tcl_string $db "select count(team_id) from edu_teams where class_id = $class_id"]</a>"
}

append manage_users_text "
</ul>
"


#
#
#  Begin the code to generate spam stuff
#
#

set spam_permission_p [ad_permission_p $db "" "" "Spam Users" $user_id $class_id]
if {$spam_permission_p && ($n_profs > 0 || $n_tas > 0 || $n_students > 0 || $n_dropped > 0)} {
    set spam_text "
    <h3>Spam</h3>
    <ul>
    "

    if {$n_profs > 0} {
	append spam_text "
	<li><a href=\"spam.tcl?who_to_spam=[ns_urlencode [list [edu_get_professor_role_string]]]\">Spam all Professors</a></li>
	"
    }

    if {$n_profs > 0 && $n_tas > 0} {
	append spam_text "
	<li><a href=\"spam.tcl?who_to_spam=[ns_urlencode [list [edu_get_professor_role_string] [edu_get_ta_role_string]]]\">Spam all Professors and TAs</a></li>
	"
    }

    if {$n_students > 0} {
	append spam_text "
	<li><a href=\"spam.tcl?who_to_spam=[ns_urlencode [list [edu_get_student_role_string]]]\">Spam all Students</a></li>
	"
    }

    append spam_text "
    <li><a href=\"spam.tcl?who_to_spam=[ns_urlencode [list [edu_get_professor_role_string] [edu_get_ta_role_string] [edu_get_student_role_string]]]\">Spam the Entire Class</a></li>
    "

    if {$n_dropped > 0} {
	append spam_text "
	<li><a href=\"spam.tcl?who_to_spam=[ns_urlencode [list [edu_get_dropped_role_string]]]\">Spam all students who have dropped the class</a>
	"
    }

    # only disply the history link when there is a history to show.

    set n_spams_sent [database_to_tcl_string $db "select count(spam_id) from group_spam_history where group_id = $class_id"]

    if {$n_spams_sent  > 0} {
	append spam_text "
	<p>
	<li> Past Spams: <a href=\"spam-history.tcl?group_id=$class_id\">$n_spams_sent</a>
	"
    }

    append spam_text "</ul>"
} else {
    set spam_text ""
}

#
#
#  Begin the code to generate projects
#
#

set projects_text "
<h3>Projects</h3>
<ul>
"

# lets get the projects out of the database (if there are any)

set project_list [database_to_tcl_list_list $db "select project_name, project_id from edu_projects where class_id = $class_id"]

if {![empty_string_p $project_list]} {

    foreach project $project_list {
	append projects_text "<li><a href=\"projects/one.tcl?project_id=[lindex $project 1]\">[lindex $project 0]</a>"
	
	# now, if there are project instances, lets list them
	set selection [ns_db select $db "select project_instance_name, project_instance_id from edu_project_instances where project_id = [lindex $project 1] and active_p = 't'"]

	set n_subprojects 0
	while {[ns_db getrow $db $selection]} {
	    set_variables_after_query
	    if {$n_subprojects == 0} {
		append projects_text "<ul>"
	    }
	    append projects_text "<li><a href=\"projects/instance-info.tcl?project_instance_id=$project_instance_id\">$project_instance_name</a>"
	    incr n_subprojects
	}
	
	if {$n_subprojects > 0} {
	    append projects_text "</ul>"
	}
    }

    append projects_text "<p>"

}

append projects_text "
<li> <a href=\"task-add.tcl?task_type=project\">Add a Project</a></li>
</ul>
"

#
#
#  Begin the code to generate exams
#
#


if {[string compare $exams_p t] == 0} {
    set exam_text "
    <h3>Exams</h3>
    <ul>
    "
    
    set selection [ns_db select $db "select exam_name, exam_id from edu_exams where class_id = $class_id order by date_administered"]


    set count 0
    
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	incr count
	append exam_text "<li><a href=\"exam-info.tcl?exam_id=$exam_id\">$exam_name</a> \n"
	set return_url [ns_conn url]
    }
    
    if {$count > 0} {
	append exam_text "<br><br>"
    }
    
    append exam_text "
    <li> <a href=\"exam-add.tcl\">Add an Exam</a>
    </ul>
    "
} else {
    set exam_text ""
}

#
#
#  Begin the code to generate textbooks
#
#


set textbook_text "
<h3>Textbooks</h3>
<ul>
"

set selection [ns_db select $db "select title, 
                          edu_textbooks.textbook_id 
                     from edu_textbooks, 
                          edu_classes_to_textbooks_map map 
                    where edu_textbooks.textbook_id = map.textbook_id 
                      and map.class_id = $class_id 
                 order by title"]

set count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append textbook_text "<li><a href=\"/class/textbook-info.tcl?textbook_id=$textbook_id\">$title</a>
    [ad_space 4] <a href=\"textbooks/remove.tcl?textbook_id=$textbook_id\">Remove</a>"
     incr count
}

if {$count > 0} {
    append textbook_text "<p>"
}

append textbook_text "
<li> <a href=\"textbooks/add.tcl\">Add a Text Book</a>
</ul>
"

#
#
#  Begin the code to generate Grades
#
#

if {[string compare $grades_p t] == 0} {
    set grades_text "
    <h3>Grades</h3>
    <ul>"
    
    set selection [ns_db select $db "
    select grade_name, weight, grade_id
    from edu_grades where class_id=$class_id"]
    set count 0
    
    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	
	append grades_text "
	<li><a href=grades-view.tcl?grade_id=$grade_id>$grade_name</a> - $weight\%"
	incr count
    }
    
    if {!$count} {
	append grades_text "
	<p>No grade policy has been set"
    }

    append grades_text "
    <p><a href=grade-policy-edit.tcl>Edit Grade Policy</a>
    </ul>
    "
} else {
    set grades_text ""
}

#
#
#  Begin the code to generate sections
#
#


set section_text "
<h3>Sections</h3>
<ul>
"

set selection [ns_db select $db "select section_id, section_name from edu_sections where class_id = $class_id"]

set n_sections 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr n_sections
    append section_text "<li><a href=\"section-info.tcl?section_id=$section_id\">$section_name</a> \n"
}

if {$n_sections > 0} {
    append section_text "<p>"
}


append section_text "
<a href=\"users/index.tcl?target_url=[ns_urlencode "[edu_url]class/admin/section-add-edit.tcl"]&type=section_leader\">Add a Section</a>
</ul>
"



ns_return 200 text/html "
$header
$news_text
$class_resources
$lecture_notes_text
$handouts_text
$assignments_text
$manage_users_text
$spam_text
$projects_text
$exam_text
$textbook_text
$grades_text
$section_text
</blockquote>
[ad_footer]
"
