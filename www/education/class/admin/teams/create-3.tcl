# 
# /www/education/class/admin/teams/create-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu
#
# this page is a confirmation to allow the user to check the information
# about a team before it is created.
#

ad_page_variables {
    team_name
    team_id
    {student_id ""}
    {return_url ""}
    {project_instance_id ""}
}


if {[empty_string_p $return_url]} {
    set return_url "one.tcl?team_id=$team_id"
} 

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]
set user_id [lindex $id_list 0]

# check for a double click
if {[database_to_tcl_string $db "select count(group_name) from user_groups where group_id = $team_id"] > 0} {
    ad_returnredirect "$return_url"
    return
}



ad_user_group_add $db edu_team $team_name t f closed f "" $team_id


# the ad_user_group_add proc does not quite work because it does not
# allow for subgroups so we do the update

ns_db dml $db "update user_groups set parent_group_id = $class_id where group_id = $team_id"

if {![empty_string_p $student_id]} {
    ad_user_group_user_add $db $user_id member $class_id
}

if {![empty_string_p $project_instance_id]} {
    ns_db dml $db "insert into edu_project_user_map (project_instance_id, team_id) values ($project_instance_id, $team_id)"
}

ns_db releasehandle $db

ad_returnredirect $return_url





