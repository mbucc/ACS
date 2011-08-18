#
# /www/education/class/admin/projects/instance-add-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page gathers the data, and then either
# 1. stuffs it into a URL and redirects the user to select
#    the student
# or
# 2. displays the information for selecting a team for this project

ad_page_variables {
    project_id
    {project_instance_name ""}
    project_type
    {url ""}
    {description ""}
}


set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $project_id]} {
    incr exception_count 
    append exception_text "<li>You must provide the parent project identification number."
} else {
 set selection [ns_db 0or1row $db "select project_name
        from edu_projects
       where project_id = $project_id
         and class_id = $class_id"]
    
    if {$selection == ""} {
	incr exception_count
	append exception_text"<li>There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
    } else {
	set_variables_after_query
    }
}

if {[empty_string_p $project_type]} {
    incr exception_count
    append exception_text "<li>You must select the type of this project."
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

if {[string compare $url "http://"] == 0} {
    set url ""
}


# if the project is of type 'user' then we redirect to let
# the admin select the appropriate student
# else
# we display this page which lets the admin select the correct team

if {[string compare $project_type user] == 0} {
    set target_url_vars [export_url_vars project_id project_instance_name project_type url description]
    set target_url "[edu_url]class/admin/projects/instance-add-3.tcl"
    set view_type project
    set export_vars [export_url_vars target_url_vars target_url view_type project_instance_name]
    ns_db releasehandle $db
    ad_returnredirect "[edu_url]class/admin/users/students-view.tcl?$export_vars"
    return
}


# if they have selected a team project, we need to have the
# a project_instance_name

if {[empty_string_p $project_instance_name]} {
    ad_return_complaint 1 "<li>You must project a name for this project instance."
    return
}


# this means that this is a team project

set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>Add a Project Instance</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "Add Project Instance"]

<hr>
for $project_name
<blockquote>

<form method=post action=\"instance-add-3.tcl\">
[export_form_vars project_id project_instance_name project_type url description]

<table>
<tr>
<th align=right>Project Instance Name:</th>
<td>[edu_maybe_display_text $project_instance_name]
</tr>

<tr>
<th align=right>URL:</th>
<td>[edu_maybe_display_text $url]
</tr>

<tr>
<th align=right>Description:</th>
<td>[edu_maybe_display_text $description]
</tr>

<tr>
<th align=right>Number of students:</th>
<td>
Min [ad_space] <input type=text name=min_body_count size=2 maxlength=2>
[ad_space 2] Max [ad_space] <input type=text name=max_body_count size=2 maxlength=2>
</td>

<tr>
<th align=right>
Team Assignment:
</th>
<td>
<select name=\"team_id_or_new_or_none\">
<option value=\"new\">Create a new team
"

# Get a list of teams in this class that haven't yet
# been assigned to a project.
set unassigned_team_list [database_to_tcl_list_list $db "select et.team_id,
       team_name
from edu_teams et,
     edu_project_user_map epum
where et.team_id = epum.team_id(+)
  and epum.team_id is null
  and et.class_id = $class_id"]


foreach unassigned_team $unassigned_team_list {
    set team_id [lindex $unassigned_team 0]
    set team_name [lindex $unassigned_team 1]
    append return_string "<option value=\"$team_id\">$team_name
"
}

append return_string "
<option value=\"none\">None, will assign later
</select>
</td>

<tr>
<td colspan=2 align=center>
<input type=submit value=\"Continue\">
</td>
</tr>
</table>
</form>
</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string






