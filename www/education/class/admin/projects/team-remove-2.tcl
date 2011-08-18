#
# /www/education/class/admin/projects/team-remove-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# allows a user to unassociate a team and a project instance
#

ad_page_variables {
    project_instance_id
    team_id
    {return_url ""}
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

if {[empty_string_p $return_url]} {
    if {[empty_string_p $project_instance_id]} {
	set return_url ""
    } else {
	set return_url "instance-info.tcl?project_instance_id=$project_instance_id"
    }
}


# if project_instance_id or team_id is null, lets just do an appropriate
# redirect.  Otherwise, make sure that the project is part of this class
# and if so, do the delete.  We don't need to check to see if the team is 
# assigned to the project because if they are not the delete will not do
# anything

if {![empty_string_p $project_instance_id] && ![empty_string_p $team_id]} {

    if {[database_to_tcl_string $db "select count(proj.project_id) from edu_projects proj, edu_project_instances inst where inst.project_id = proj.project_id and proj.class_id = $class_id and inst.project_instance_id = $project_instance_id"] > 0} {
	# then we are in the correct class
	ns_db dml $db "delete from edu_project_user_map where project_instance_id = $project_instance_id and team_id = $team_id"
    }
}

ns_db releasehandle $db

ad_returnredirect $return_url




