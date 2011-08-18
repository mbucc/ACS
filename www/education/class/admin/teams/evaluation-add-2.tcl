#
# /www/education/class/admin/teams/evaluation-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This is a confirmation page that allows the user to review the
# team evaluation before submitting it
#

ad_page_variables {
    team_id
    evaluation_type
    {grade ""}
    comments
    {show_team_p f}
}



set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set grader_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set team_name [database_to_tcl_string_or_null $db "select team_name from edu_teams where team_id=$team_id"]

if {$team_name==""} {
    incr error_count
    append error_text "<li>You must call this page with a valid Team ID"
}

set error_count 0
set error_text ""

if {[empty_string_p $grade] && [empty_string_p $comments]} {
    incr error_count
    append error_text "<li>You must enter either a grade or comments"
}

if {[empty_string_p $evaluation_type]} {
    incr error_count
    append error_text "<li>You must specify an evaluation type"
}

if {$error_count} {
    ad_return_complaint $error_count $error_text
    return
}


set evaluation_id [database_to_tcl_string $db "select edu_evaluation_id_sequence.nextval from dual"]


set return_string "
[ad_header "Team Evaluations @ [ad_system_name]"]

<h2>Confirm Evaluation for $team_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" "Teams"] [list one.tcl?team_id=$team_id "One Team"] "Add Evaluation"]

<hr>
<blockquote>

<form method=post action=\"evaluation-add-3.tcl\">

[export_form_vars evaluation_id evaluation_type team_id comments grade show_team_p]

<table>
<tr>
<th align=right>Evaluation Type</th>
<td>$evaluation_type</td>
</tr>
<tr>
<th align=right>Grade</th>
<td>[edu_maybe_display_text $grade]</td>
</tr>
<tr>
<th align=right>Comments</th>
<td>[edu_maybe_display_text $comments]</td>
</tr>
<tr>
<th align=right>Make Evaluation Visible to Team?</th>
<td>[ec_PrettyBoolean $show_team_p]</td>
</tr>
<tr>
<th></th>
<td><input type=submit value=Confirm></td>
</tr>
</table>
</form>
</blockquote>
[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string




