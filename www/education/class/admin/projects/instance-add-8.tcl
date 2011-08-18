#
# /www/education/class/admin/projects/instance-add-3.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# the actually adds the project instance to the database
#

ad_page_variables {
    project_id
    project_instance_name 
    project_instance_id
    project_type
    {url ""}
    {description ""}
    {max_body_count ""}
    {min_body_count ""}
    {team_name ""}
    {team_id ""}
    {student_id ""}
}

# ad_page_variables defaulting doesn't work when
# the form var is defined but empty.
if [empty_string_p $max_body_count] {
    set max_body_count NULL
}
if [empty_string_p $min_body_count] {
    set max_body_count NULL
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $project_id]} {
    ad_return_complaint 1 "<li>You must provide a project identification number"
} else {

 set selection [ns_db 0or1row $db "select project_name
        from edu_projects
       where project_id = $project_id
         and class_id = $class_id"]
    
    if {$selection == ""} {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    } else {
	set_variables_after_query
    }
}


# lets check for double click

if {[database_to_tcl_string $db "select count(project_instance_id) from edu_project_instances where project_instance_id = $project_instance_id"] > 0} {
    # it was a double click
    ad_returnredirect "one.tcl?project_id=$project_id"
    return
}


ns_db dml $db "insert into edu_project_instances (
     project_instance_id, 
     project_id, 
     project_instance_name,  
     project_instance_url, 
     description, 
     approved_p, 
     approved_date, 
     approving_user, 
     max_body_count,
     min_body_count,
     active_p) 
  values (
     $project_instance_id,
     $project_id,
     [ns_dbquotevalue $project_instance_name],
     [ns_dbquotevalue $url],
     [ns_dbquotevalue $description],
     't',
     sysdate,
     $user_id,
     $max_body_count,
     $min_body_count,
     't')"


set return_url "/education/class/admin/projects/one.tcl?project_id=$project_id"

if ![empty_string_p $team_id] {

    # We got a team_id, add it to this instance
    if { [database_to_tcl_string $db "select count(*)
from edu_teams
where team_id = $team_id"] > 0 } {
        # The team exists.  Put an entry into the project_user_map.
        if { [database_to_tcl_string $db "select count(*)
from edu_project_user_map
where project_instance_id = $project_instance_id
and team_id = $team_id"]                          == 0 } {
            # No entries in the map.  This is not a double click.
            ns_db dml $db "insert into edu_project_user_map (project_instance_id, team_id) values ($project_instance_id, $team_id)"
        }
    } else {
	# The team doesn't yet exist.  We need to create it and put an
        # entry in the edu_project_user_map.
	ad_returnredirect /education/class/admin/teams/create-3.tcl?[export_url_vars team_id team_name project_instance_id return_url]
	return
    }
}

ad_returnredirect $return_url
