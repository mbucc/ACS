#
# /www/education/class/admin/projects/team-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# allows a user to associate a team with a project instance
#

ad_page_variables {
    project_instance_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
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
	project_instance_name,
	project_instance_url,
	inst.description
   from edu_project_instances inst,
        edu_projects proj
  where project_instance_id = $project_instance_id
    and proj.project_id = inst.project_id 
    and proj.class_id = $class_id"]

    
    if {$selection == ""} {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    } else {
	set_variables_after_query
    }
}


# lets get the list of teams that can be assigned to this project instance
# if there are no teams available, we redirect to allow the use to
# create a new team that is then associated with this

set teams_list [database_to_tcl_list_list $db "select team_id, team_name from edu_teams where class_id = $class_id and not exists (select 1 from edu_project_user_map map where project_instance_id = $project_instance_id and map.team_id = edu_teams.team_id)"]

if {[empty_string_p $teams_list]} {
    set return_url "../projects/instance-info.tcl?project_instance_id=$project_instance_id"
    ad_returnredirect "../teams/create.tcl?[export_url_vars return_url project_instance_id]"
    return
} elseif {[llength $teams_list] == 1} {
    # there is only one team they can choose so force them to choose it
    ad_returnredirect "team-add-2.tcl?team_id=[lindex [lindex $teams_list 0] 0]&project_instance_id=$project_instance_id"
    return
}



set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>Add a Team</h2>
to $project_instance_name
<p>
[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "Add Team"]

<hr>
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
[edu_maybe_display_text $project_instance_url]
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>
</table>
<h3>Available Teams</h3>
<ul>
"

# lets display the list of teams to choose from

foreach team $teams_list {
    append return_string "<li><a href=\"team-add-2.tcl?project_instance_id=$project_instance_id&team_id=[lindex $team 0]\">[lindex $team 1]</a></li>\n"
}


append return_string "

</ul>
</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string







