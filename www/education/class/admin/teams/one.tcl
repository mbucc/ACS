#
# /www/education/class/admin/teams/one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays information about a given team
#

ad_page_variables {
    team_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set exception_count 0
set exception_text ""

if {[empty_string_p $team_id]} {
    incr exception_count
    append exception_text "<li>You must provide a team identification number"
} else {
    set selection [ns_db 0or1row $db "select
                     team_name
                from edu_teams
               where team_id = $team_id
                 and class_id = $class_id"]

    if {$selection == ""} {
	incr exception_count
	append exception_text "<li>The team number that you have provided is not a team in this class."
    } else {
	set_variables_after_query
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}



set return_string "
[ad_header "One Team in $class_name @ [ad_system_name]"]
<h2>$team_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "Teams"] "One Team"]

<hr>

<blockquote>

<table>

<h3>Team Members</h3>
<ul>
"

# Note: we don't explicitly use the last_name column but the query
# breaks if you remove it.  See Oracle error ORA-01791.
set selection [ns_db select $db "select distinct users.user_id as student_id, 
             first_names || ' ' || last_name as student_name,
             last_name
        from edu_teams, 
             user_group_map map, 
             users 
       where team_id = map.group_id 
         and map.user_id = users.user_id
         and team_id = $team_id
     order by last_name"]

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    append return_string "<li><a href=\"../users/student-info.tcl?student_id=$student_id\">$student_name</a> &nbsp &nbsp (<a href=\"user-remove.tcl?student_id=$student_id&team_id=$team_id\">remove from team</a>)\n"
    incr count
}

if {$count == 0} {
    append return_string "There are not currently any students assigned to this team.<br><Br>"
} else {
    append return_string "
    <Br><Br>
    <li><a href=\"../spam.tcl?who_to_spam=member&subgroup_id=$team_id\">Spam Team</a>
    "

    # if some spams have already been sent, lets link to them here
    set n_spams_sent [database_to_tcl_string $db "select count(spam_id) from group_spam_history where group_id = $team_id"]
    if {$n_spams_sent > 0} {
	append return_string "[ad_space 1] (<a href=\"../spam-history.tcl?group_id=$team_id\">$n_spams_sent</a> sent)"
    }
}

if {[database_to_tcl_string $db "select count(distinct user_id) from user_group_map where group_id = $class_id and role = '[edu_get_student_role_string]'"] > $count} {
    set target_url "[edu_url]class/admin/teams/user-add.tcl"
    set a [ns_conn urlv]
    append return_string "
    <li><a href=\"../users/students-view.tcl?view_type=team_student_add&team_id=$team_id&target_url=[ns_urlencode "$target_url"]&target_url_vars=[ns_urlencode "team_id=$team_id"]\">Add a Team Member</a>"
}


append return_string "
</ul>


<h3>Projects</h3>
<ul>
"

set selection [ns_db select $db "select map.project_instance_id, 
        project_instance_name, 
        project_instance_url, 
        nvl(inst.description, proj.description) as description
   from edu_project_instances inst, 
        edu_project_user_map map,
        edu_projects proj
  where team_id = $team_id 
    and map.project_instance_id = inst.project_instance_id
    and inst.project_id = proj.project_id"]

set n_projects 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr n_projects
    append return_string "<li><a href=\"../projects/instance-info.tcl?project_instance_id=$project_instance_id\">$project_instance_name</a> - $description"
    if {![empty_string_p $project_instance_url]} {
	append return_string " (<a href=\"$project_instance_url\">$project_instance_url</a>)"
    }
}

if {$n_projects == 0} {
    append return_string "This team has not been assigned to any projects."
}



append return_string "
<p>
Project-add-team.tcl
</ul>

<h3>Evaluations</h3>
<ul>"

# now get the evaluations (excluding assignments) for the student

set selection [ns_db select $db "
select e.grader_id,
first_names || ' ' || last_name as grader_name,
evaluation_type,
grade,
comments,
evaluation_date,
evaluation_id
from edu_student_evaluations e,
users
where e.team_id=$team_id
and users.user_id = e.grader_id
and e.class_id=$class_id"]

set count 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    incr count
    append return_string "
    <p>
    <table>
    <tr>
    <th align=right>Evaluation Type:</th>
    <td>$evaluation_type</td>
    </tr>
    <tr>
    <th align=right>Grade:</th>
    <td>$grade</td>
    </tr>
    <tr>
    <th align=right>Comments:</th>
    <td>$comments</td>
    </tr>
    <tr>
    <th align=right>Evaluated By:</th>
    <td><a href=\"../users/one.tcl?user_id=$grader_id\">$grader_name</a></td>
    </tr>
    <tr>
    <th align=right>Evaluation Date:</th>
    <td>[util_AnsiDatetoPrettyDate $evaluation_date]</td>
    </tr>
    </table>
    </p>"
}

if {!$count} {
    append return_string "No evaluations available."
}

append return_string "
<p><a href=\"evaluation-add.tcl?team_id=$team_id\">Add an Evaluation</a>
</ul>
<p>
<a href=\"edit.tcl?team_id=$team_id\">edit team name</a>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string






