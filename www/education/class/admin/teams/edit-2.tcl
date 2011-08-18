#
# /www/education/class/admin/teams/edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page confirms the new name for the team
#

ad_page_variables {
    team_name
    team_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

if {[empty_string_p $team_name]} {
    ad_return_complaint 1 "<li>You must include a name for this team."
    return
} 

if {[empty_string_p $team_id]} {
    ad_return_complaint 1 "<li>You must provide a team to edit"
    return
}

# lets ensure that this team is part of this class

if {[database_to_tcl_string $db "select count(team_id) from edu_teams where team_id = $team_id and class_id = $class_id"] == 0} {
    ad_return_complaint 1 "<li>The team that you are trying to edit does not belong to $class_name."
    return
}


set return_string "
[ad_header "Edit Team Information"]

<h2>Edit Team Information</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Teams] [list "one.tcl?team_id=$team_id" "One Team"] "Edit Team Information"]

<hr>
<blockquote>

<form method=post action=\"edit-3.tcl\">

[export_form_vars team_name team_id]

<b>Team Name</b>:
[ad_space 2]
$team_name

<p>

<input type=submit value=\"Confirm Edit\">

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
