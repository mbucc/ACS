#
# /www/education/class/projects/instances/index.tcl
#
# by aegrumet@arsdigita.com, March 3, 2000
#
# this page displays project assignments and allows self-assignment
# if the appropriate flag is set
#

ad_page_variables {
    project_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set exception_count 0
set exception_text ""

if {[empty_string_p $project_id]} {
    ad_return_complaint 1 "<li>You must provide a project identification number"
    return
} else {
    set project_name [database_to_tcl_string $db "select project_name
from edu_projects
where project_id = $project_id"]
    if [empty_string_p $project_name] {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    }
}

# We found the project.

# Get a list of project instances
set instance_list [database_to_tcl_list_list $db "select project_instance_id,
       project_instance_name
from edu_project_instances
where project_id = $project_id
  and active_p = 't'"]

# Loop through the list and construct the main table
set main_table "
<table width=100%>
<tr>
 <th align=left>Title</th>
 <th>Students</th>
</tr>
"

set n_instances 0
foreach instance $instance_list {
    set project_instance_id [lindex $instance 0]
    set project_instance_name [lindex $instance 1]
    incr n_instances   

    if [expr ($n_instances+1) % 2] {
	set bgcolor "#FFFFFF"
    } else {
	set bgcolor "#EEEEEE"
    }

    append main_table "
<tr bgcolor=$bgcolor>
  <td align=left><a href=\"project.adp?[export_url_vars project_instance_id]\">$project_instance_name</a></td>
<td align=center>"

    # Query for students assigned to the instance.
    set selection [ns_db select $db "select user_id,
       (first_names || ' ' || last_name) as full_name,
       -1 as team_id
from users,
     edu_project_user_map
where project_instance_id = $project_instance_id
  and team_id is null
  and user_id = student_id
union
select users.user_id,
       (first_names || ' ' || last_name) as full_name,
       team_id
from users,
     user_group_map,
     edu_project_user_map
where project_instance_id = $project_instance_id
  and student_id is null
  and team_id = group_id
  and user_group_map.user_id = users.user_id"]

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	append main_table "
$full_name<br>"
    }

    append main_table "
</td></tr>"
}

if $n_instances {
    append main_table "
</table>"
} else {
    set main_table "There were no project instances in our database.\n"
}

set page_html "
[ad_header "One Project @ [ad_system_name]"]

<h2>$project_name Assignments</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl?class_id=$class_id" "$class_name Home"] [list "../" "All Projects"] [list ../one.tcl?[export_url_vars project_id] "One Project"] Assignments]

<hr>

$main_table

[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $page_html

