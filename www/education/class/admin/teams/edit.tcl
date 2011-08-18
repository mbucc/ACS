#
# /www/education/class/admin/teams/edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows a user to edit the properties of a team
#

ad_page_variables {
    team_id
}

if {[empty_string_p $team_id]} {
    ad_return_complaint 1 "<li>You must provide a team to edit."
    return
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]
set user_id [lindex $id_list 0]


set team_name [database_to_tcl_string_or_null $db "select team_name from edu_teams where class_id = $class_id and team_id = $team_id"]

if {[empty_string_p $team_name]} {
    ad_return_complaint 1 "<li>The team you have requested is not associated with this class.
    return
} 


set return_string "
[ad_header "Edit Team Information @ [ad_system_name]"]

<h2>Edit Team Information</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Teams] [list "one.tcl?team_id=$team_id" "One Team"] "Edit Team Information"]

<hr>
<blockquote>

<form method=post action=\"edit-2.tcl\">
[export_form_vars team_id]

<b>Team Name</b>:
[ad_space 2]

<input type=text size=30 maxsize=100 name=team_name value=\"$team_name\">

<p>
<input type=submit value=Continue>

</form>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
