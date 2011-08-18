#
# /www/education/class/admin/teams/user-add.tcl
#
# randyg@arsdigita.com, aileen@mit.edu, February 2000
#
# this page confirms the addition of the student to the team
#

ad_page_variables {
    team_id
    student_id
    {return_url ""}
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

    set selection [ns_db 0or1row $db "select count(member_id) as member_p,
             team_name,
             first_names, 
             last_name 
        from users, 
             edu_teams, 
             (select distinct user_id as member_id from user_group_map where group_id = $team_id) team_members
       where users.user_id = $student_id
         and edu_teams.team_id = $team_id
         and edu_teams.class_id = $class_id
         and users.user_id = team_members.member_id(+)
    group by team_name, first_names, last_name"]


    if {$selection == ""} {
	incr exception_count
	append exception_text "<li>The team number that you have provided is not a team in this class."
    } else {
	set_variables_after_query

	# in this case, we want to see if the user is already a member

	if {$member_p != 0} {
	    incr exception_count
	    append exception_text "<li>$first_names $last_name is already a member of this team."
	}
    }
}


if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}


set group_id $team_id

if {[empty_string_p $return_url]} {
    set return_url "[edu_url]class/admin/teams/one.tcl?team_id=$team_id"
}

set return_string "
[ad_header "Add a Student to $team_name @ [ad_system_name]"]
<h2>Add a student to $team_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "Teams"] [list "one.tcl?team_id=$team_id" "One Team"] "Add a User"]

<hr>

<blockquote>

<form method=post action=\"../group-user-add.tcl\">
[export_form_vars group_id student_id return_url]

Are you sure you wish to add <u>$first_names $last_name</u> to $team_name?
<p>
<input type=submit value=\"Add Student\">

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







