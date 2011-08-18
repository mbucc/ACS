#
# /www/education/class/projects/one.tcl
#
# by aegrumet@arsdigita.com, March 3, 2000
#
# this page displays information about a given project
#

ad_page_variables {
    project_id
}

set db [ns_db gethandle]

set id_list [edu_user_security_check $db]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $project_id]} {
    ad_return_complaint 1 "<li>You must provide a project identification number"
} else {

 set selection [ns_db 0or1row $db "select
             class_id, 
             project_name,
             description,
             date_assigned,
             requires_grade_p,
             last_modified,
             due_date,
             weight,
             ver.file_id,
             file_extension,
             version_id,
             ver.url
        from edu_projects,
             fs_versions_latest ver
       where project_id = $project_id
         and edu_projects.file_id = ver.file_id(+)
         and class_id = $class_id"]

    if {$selection == ""} {
	ad_return_complaint 1 "There are no projects in this class corresponding to the provided identification number.  This is an error in our code.  Please contact <a href=mailto:[ad_system_owner]>[ad_system_owner]</a>."
	return
    } else {
	set_variables_after_query
    }
}



set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>$project_name</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "All Projects"] "One Project"]

<hr>
<blockquote>


<table BORDER=0>

<tr>
<th valign=top align=right> Project Name: </td>
<td valign=top>
"
if {![empty_string_p $url]} {
    append return_string "<p> <a href=\"$url\">$project_name</a>"
} elseif {![empty_string_p $version_id]} {
    append return_string "<a href=\"/file-storage/download/$project_name.$file_extension?version_id=$version_id\">$project_name</a>"
} else {
    append return_string "$project_name"
} 	    

append return_string "
</td>
</tr>

<tr>
<th valign=top align=right> Description: </td>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>

<tr>
<th valign=top align=right> Due Date: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $due_date]
</td>
</tr>

<tr>
<th valign=top align=right> Date Assigned: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $date_assigned]
</td>
</tr>

<tr>
<th valign=top align=right>Will this project<br>be graded? </td>
<td valign=top>
[util_PrettyBoolean $requires_grade_p]
</td>
</tr>

<tr>
<th valign=top align=right> Fraction of Final Grade: </td>
<td valign=top>"

if {[empty_string_p $weight]} {
    append return_string "N/A"
} else {
    append return_string "$weight"
}

append return_string "
<tr>
<th valign=top align=right> Last Modified: </td>
<td valign=top>
[util_AnsiDatetoPrettyDate $last_modified]
</td>
</tr>


</table>
<br>
"
set task_type project
set task_id $project_id

append return_string "
<h3>Project Instances</h3>
<ul>
"

set selection [ns_db select $db "select project_instance_id, project_instance_name, project_instance_url, description from edu_project_instances where project_id = $task_id and active_p = 't'"] 

set n_project_instances 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "<li><a href=\"instance-info.tcl?project_instance_id=$project_instance_id\">$project_instance_name</a>"

    if {![empty_string_p $project_instance_url]} {
	append return_string "&nbsp (<a href=\"$project_instance_url\">$project_instance_url</a>)"
    }

    incr n_project_instances
}

if {$n_project_instances == 0} {
    append return_string "There are not currently any projects being worked on.<br><Br>"
} else {
    append return_string "<p>"
}

append return_string "
<li><a href=\"instances/index.tcl?project_id=$project_id\">View assignments</a>
</ul>

</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string






