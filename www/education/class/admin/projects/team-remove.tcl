#
# /www/education/class/admin/projects/team-remove.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# allows a user to unassociate a team and a project instance
#

ad_page_variables {
    project_instance_id
    team_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $project_instance_id]} {
    ad_return_complaint 1 "<li>You must provide a project identification number"
    return
} else {
    set selection [ns_db 0or1row $db "select
	proj.project_id,
	project_instance_name,
	project_instance_url,
	inst.description
   from edu_project_instances inst,
        edu_projects proj
  where project_instance_id = $project_instance_id
    and proj.project_id = inst.project_id 
    and proj.class_id = $class_id"]

    if {$selection == ""} {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    } else {
	set_variables_after_query
    }
}

set team_name [database_to_tcl_string_or_null $db "select team_name from edu_teams where team_id = $team_id and class_id = $class_id"]


ns_db releasehandle $db

if {[empty_string_p $team_name]} {
    # there is not team with the given id that belongs to this class so just
    # redirect (we do this to make sure that a user that is not a member of this
    # class cannot see the name of the team
    ad_returnredirect "instance-info.tcl?project_instance_id=$project_instance_id"
    return
}


set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>Remove Team</h2>
from $project_instance_name
<p>
[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "Remove Team"]

<hr>
<blockquote>

Are you sure you wish to remove $team_name from $project_instance_name?

<form method=post action=\"team-remove-2.tcl\">
[export_form_vars project_instance_id team_id]

<input type=submit value=\"Remove Team\">

</form>

</blockquote>

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







