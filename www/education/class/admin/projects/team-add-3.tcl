#
# /www/education/class/admin/projects/team-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# allows a user to associate a team with a project instance
#

ad_page_variables {
    project_instance_id
    team_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

if {[empty_string_p $team_id] || [empty_string_p $project_instance_id]} {
    ad_return_complaint 1 "<li>You must provide both a team and a project instance."
    return
}


# lets make sure that both the team and project belong to the same
# class

set same_class_p [database_to_tcl_string $db "select count(edu_teams.class_id) 
     from edu_projects, 
          edu_project_instances pi, 
          edu_teams   
   where edu_teams.class_id = edu_projects.class_id 
     and edu_teams.class_id = $class_id 
     and edu_projects.project_id = pi.project_id"]


if {$same_class_p == 0} {
    ad_return_complaint 1 "<li>The team and project must both be in the same class."
    return
}


# now we want to check for a double click

if {[database_to_tcl_string $db "select count(team_id) from edu_project_user_map where team_id = $team_id and project_instance_id = $project_instance_id"] > 0} {
    ad_returnredirect "instance-info.tcl?project_instance_id=$project_instance_id"
    return
}


ns_db dml $db "insert into edu_project_user_map (
       project_instance_id,
       team_id)
    values (
       $project_instance_id,
       $team_id)"


ns_db releasehandle $db

ad_returnredirect "instance-info.tcl?project_instance_id=$project_instance_id"
