#
# /www/education/class/admin/users/student-assign-to-team.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this adds a user to an already existing team
#

ad_page_variables {
    student_id
    return_url
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set full_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id=$student_id"]

set selection [ns_db select $db "
select t.team_name, t.team_id from edu_teams t
where class_id=$class_id
and team_id not in (select group_id from user_group_map where user_id = $student_id and class_id = $class_id)"]

append return_string "
[ad_header "Assign Student to a Team"]

<h2>Assign Student to a Team</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "students-view.tcl" "Students"] [list "student-info.tcl?student_id=$student_id" "One Student"] "Assign Team"]

<hr>

<blockquote>
"

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <li>$team_name [ad_space 2] - [ad_space 2]
    <a href=\"../teams/user-add.tcl?[export_url_vars student_id team_id return_url]\">Assign</a>"

    incr count
}

if {$count == 0} {
    append return_string "
    There are currently no teams for $class_name where $full_name is not already a member.<br>\n"
}

append return_string "
<p><a href=\"../teams/create.tcl?student_id=$student_id&[export_url_vars return_url]\">Create a team</a>

</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string












