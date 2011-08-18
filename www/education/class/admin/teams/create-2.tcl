# 
# /www/education/class/admin/teams/create-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page is a confirmation to allow the user to check the information
# about a team before it is created.
#

ad_page_variables {
    {project_instance_id ""}
    team_name
    {student_id ""}
    {return_url ""}
}


if {[empty_string_p $team_name]} {
    ad_return_complaint 1 "<li>You must provide a name for your team"
    return
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]
set user_id [lindex $id_list 0]


# teams are groups so we get the next team_id from the group sequence

set team_id [database_to_tcl_string $db "select user_group_sequence.nextval from dual"]

# Now that we have a team_id we can assign a default return_url if none
# was provided.
if [empty_string_p $return_url] {
    set return_url one.tcl?[export_url_vars team_id]
}


set return_stirng "
[ad_header "Confirm New Team"]

<h2>Confirm New Team</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" "Teams"] "Create New Team"]

<hr>
<blockquote>

<form method=post action=\"create-3.tcl\">
[export_form_vars project_instance_id team_name team_id return_url student_id]

<table>
<tr><th align=right>Team Name:</th>
<td>$team_name</td>
</tr>
"

if {![empty_string_p $project_instance_id]} {
    set project_instance_name [database_to_tcl_string_or_null $db "select project_instance_name from edu_project_instances where project_instance_id = $project_instance_id"]

    if {![empty_string_p $project_instance_name]} {
	append return_stirng "
	<tr>
	<th align=right>Project Name:</th>
	<td>$project_instance_name</td>
	</tr>
	"
    }
}

append return_stirng "
<tr><td align=center colspan=2><input type=submit value=Confirm></td></tr>
</table>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
