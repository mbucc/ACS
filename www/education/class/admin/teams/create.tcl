#
# /www/education/class/admin/teams/create.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows the user to create a team
#

ad_page_variables {
    {student_id ""} 
    {return_url ""}
    {project_instance_id ""}
}

# optionally takes student_id of the first student in the team
# project_instance_id is taken in the case that this team is being
# created to implement a project instance

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]
set user_id [lindex $id_list 0]


set return_string "
[ad_header "Create a New Team"]

<h2>Create New Team</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "Teams"] "Create New Team"]

<hr>
"

if {![empty_string_p $project_instance_id]} {
    set project_instance_name [database_to_tcl_string_or_null $db "select inst.project_instance_name from edu_project_instances inst, edu_projects proj where project_instance_id = $project_instance_id and class_id = $class_id and proj.project_id = inst.project_id"]
    if {![empty_string_p $project_instance_name]} {
	append return_string "to be added to $project_instance_name"
    }
}

append return_string "
<blockquote>
<form method=post action=\"create-2.tcl\">

[export_form_vars student_id return_url project_instance_id]

<table>
<tr>
<th align=right>Team Name</th>
<td><input type=text size=20 name=team_name></td>
</tr>
"

set selection [ns_db select $db "select unique project_instance_name, project_instance_id from edu_project_instances epi, edu_student_tasks where class_id=$class_id and epi.project_id = edu_student_tasks.task_id"]

set select_text ""
set n_projects 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append select_text "
    <option value=\"$project_instance_id\">$project_instance_name
    "

}

if {$n_projects > 0} {
    append return_string "
    <tr>
    <th align=right valign=top>Select a project<br>for this team:</th>
    <td><select name=project_instance_id>
    <option value=\"None\">"
    $select_text
    </select>
    </tr>
    "
}

append return_string "
[edu_empty_row]
<tr><th></th><td><input type=submit value=Submit></td>
</tr>
</table>
</form>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
