#
# /www/education/class/admin/teams/user-remove.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this is the confirmation page to see if the person really wants
# to remove the user from the team
#

ad_page_variables {
    team_id
    student_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $team_id]} {
    incr exception_count
    append exception_text "<li>You must provide a team number."
}

if {[empty_string_p $student_id]} {
    incr exception_count
    append exception_text "<li>You must include the student to be added to the team."
}

if {$exception_count == 0} {

    # we do an outer join here so we can see whether or not the user is 
    # already a member of the team.

    set selection [ns_db 0or1row $db "select distinct team_name,
             first_names, 
             last_name 
        from users, 
             edu_teams, 
             user_group_map map
       where users.user_id = $student_id
         and edu_teams.team_id = $team_id
         and edu_teams.class_id = $class_id
         and users.user_id = map.user_id
         and map.group_id = edu_teams.team_id"]


    if {$selection == ""} {
	incr exception_count
	append exception_text "<li>The student is not a member of this team."
    } else {
	set_variables_after_query
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set group_id $team_id

set return_url "teams/one.tcl?team_id=$team_id"

set return_string "
[ad_header "Teams for $class_name @ [ad_system_name]"]
<h2>Remove User from Team</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "Teams"] [list "one.tcl?team-id=$team_id" "One Team"] "Remove User"]

<hr>

<blockquote>

<form method=post action=\"../group-user-remove.tcl\">
[export_form_vars group_id student_id return_url]

Are you sure you wish to remove <u>$first_names $last_name</u> from $team_name?

<p>

<input type=submit value=\"Remove Student\">

</blockquote>

[ad_footer]
"



ns_db releasehandle $db

ns_return 200 text/html $return_string






