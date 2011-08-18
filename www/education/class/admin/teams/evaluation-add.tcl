#
# /www/education/class/admin/teams/evaluation-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows the admin to add an evaluation for the team
#

ad_page_variables {
    team_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set grader_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set team_name [database_to_tcl_string_or_null $db "select team_name from edu_teams where team_id=$team_id"]

if {$team_name==""} {
    ad_return_complaint 1 "<li>You must call this page with a valid Team ID"

    return
}


set return_string "
[ad_header "Team Evaluations @ [ad_system_name]"]

<h2>Evaluation for $team_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Teams] [list "one.tcl?team_id=$team_id" "One Team"] "Add Evaluation"]

<hr>
<blockquote>

<form method=post action=\"evaluation-add-2.tcl\">
<table>
<tr>
<th align=right>Evaluation Type</th>
<td><input type=text size=40 name=evaluation_type></td>
</tr>
<tr>
<th align=right>Grade</th>
<td><input type=text size=5 name=grade></td>
</tr>
<tr>
<th align=right>Comments</th>
<td>[edu_textarea comments]</td>
</tr>
<tr>
<th align=right>Make Evaluation Visible to Team?</th>
<td><input type=checkbox name=show_team_p checked></td>
</tr>
[export_form_vars team_id]
<tr>
<th></th>
<td><input type=submit value=Submit></td>
</tr>
</table>
</form>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
