#
# /www/education/class/admin/projects/instance-info.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays information about a given project
#

ad_page_variables {
    project_instance_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "View Admin Pages"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $project_instance_id]} {
    ad_return_complaint 1 "<li>You must provide a project identification number"
    return
} else {
    set selection [ns_db 0or1row $db "select
	proj.project_id,
        project_name,
	project_instance_name,
	project_instance_url,
	proj.description,
	approved_p,
        approved_date,
        approving_user,
        max_body_count,
        min_body_count,
	active_p,
        project_type
   from edu_project_instances inst,
        edu_projects proj
  where inst.project_instance_id = $project_instance_id
    and proj.project_id = inst.project_id
    and proj.class_id = $class_id"]

    
    if {$selection == ""} {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    } else {
	set_variables_after_query
    }
}


if {[string compare $project_type team] == 0} {
    if [empty_string_p $max_body_count] {
	set pretty_max_body_count "unspecified"
    } else {
	set pretty_max_body_count $max_body_count
    }
    if [empty_string_p $min_body_count] {
	set pretty_min_body_count "unspecified"
    } else {
    set pretty_min_body_count $min_body_count
    }

    set display_text "
    <tr>
    <th align=right>Number of students:</th>
    <td>
    Min: [ad_space] $pretty_min_body_count
    [ad_space] Max: [ad_space] $pretty_max_body_count
    </td>
    </tr>
    "

    # now, we want to show a list of teams that are assigned to this
    # project
    
    set teams_list [database_to_tcl_list_list $db "select edu_teams.team_id, 
                   team_name 
              from edu_teams, 
                   edu_project_instances, 
                   edu_project_user_map map 
             where map.team_id = edu_teams.team_id 
      edu_project_instances.project_instance_id = $project_instance_id 
               and map.project_instance_id = edu_project_instances.project_instance_id"]

    append display_text "
    <h3>Teams working on $project_instance_name</h3>
    <ul>
    "

    if {[empty_string_p $teams_list]} {
	append display_text "There are currently no teams assigned to this project.<p>
	<li><a href=\"team-add.tcl?project_instance_id=$project_instance_id\">Add a team</a>"
    } else {
	append display_text "<table>"
	foreach team $teams_list {
	    append display_text "
	<tr><td>
	    <a href=\"../teams/one.tcl?team_id=[lindex $team 0]\">[lindex $team 1]</a> 
	    </td><td>
	    (<a href=\"team-remove.tcl?project_instance_id=$project_instance_id&team_id=[lindex $team 0]\">remove</a>)</tr>"
	}
	append display_text "
	[edu_empty_row]
	<tr><td colspa=2>
	<a href=\"team-add.tcl?project_instance_id=$project_instance_id\">Add a team</a>
	</td>
	</tr>
	</table>"
    }
    
    append display_text "
    </ul>
    "

} else {
    set display_text ""
    
}


set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>$project_instance_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "One Project Instance"]

<hr>
a part of <a href=\"one.tcl?project_id=$project_id\">$project_name</a>
<blockquote>


<table BORDER=0>

<tr>
<th valign=top align=right> Name: </td>
<td valign=top>
$project_instance_name
</td>
</tr>

<tr>
<th valign=top align=right> URL: </td>
<td valign=top>
"

if {[empty_string_p $project_instance_url]} {
    append return_string "None"
} else {
    append return_string "<A href=\"$project_instance_url\">$project_instance_url</a>"
}

append return_string "
</td>
</tr>

$display_text

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>
</table>
 
<h4>Status Reports</h4>
<ul>
"


set comment_permission_p [database_to_tcl_string_or_null $db "select 1 from users, 
        user_group_map ug_map, 
        edu_project_user_map map 
  where users.user_id = $user_id 
    and map.project_instance_id = $project_instance_id
    and (users.user_id = map.student_id 
         or (users.user_id = ug_map.user_id 
             and ug_map.group_id = map.team_id))"]

if {[empty_string_p $comment_permission_p]} {
    set comment_permission_p [ad_permission_p $db "" "" "View Admin Pages" $user_id $class_id]
}

if {$comment_permission_p == 1} {
    set progress_reports [ad_general_comments_list $db $project_instance_id EDU_PROJECT_INSTANCES $project_instance_name]
} else {
    set progress_reports "[ad_general_comments_summary_sorted $db $project_instance_id EDU_PROJECT_INSTANCES $project_instance_name]"
}

if {[string compare $progress_reports "<ul></ul>"] == 0} {
    append return_string "No status reports available"
} else {
    append return_string "$progress_reports"
}


append return_string "
</ul>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string






