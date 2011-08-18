#
# /www/education/class/admin/projects/one.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page displays information about a given project
#

ad_page_variables {
    project_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set exception_count 0
set exception_text ""

if {[empty_string_p $project_id]} {
    ad_return_complaint 1 "<li>You must provide a project identification number"
} else {

 set selection [ns_db 0or1row $db "select
             ep.class_id, 
             ep.project_name,
             teacher_id,
             first_names,
             last_name,
             ep.description,
             ep.date_assigned,
             last_modified,
             due_date,
             grade_id,
             weight,
             electronic_submission_p,
             requires_grade_p,
             version_id, 
             file_extension,
             ver.url,
             ver.file_id
        from edu_projects ep,
             users,
             fs_versions_latest ver
       where users.user_id = ep.teacher_id
         and ep.project_id = $project_id
         and ep.class_id = $class_id
         and ep.file_id = ver.file_id(+)"]

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

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "All Projects"] "One Project"]

<hr>
<blockquote>


<table BORDER=0>

<tr>
<th valign=top align=right> Project Name: </th>
<td valign=top>
"

if {![empty_string_p $version_id]} {
    if {[fs_check_read_p $db $user_id $version_id $class_id]} {
	if {![empty_string_p $url]} {
	    append return_string "<a href=\"$url\">$project_name</a>"
	} else {
	    append return_string "<a href=\"/file-storage/download/$project_name.$file_extension?version_id=$version_id\">$project_name</a>"
	}
    } else {
	append return_string "$project_name"
    }
} else {
    append return_string "$project_name"
}

append return_string "
</td>
</tr>

<tr>
<th valign=top align=right> Description: </th>
<td valign=top>
[edu_maybe_display_text $description]
</td>
</tr>

<tr>
<th valign=top align=right> Due Date: </th>
<td valign=top>
[util_AnsiDatetoPrettyDate $due_date]
</td>
</tr>

<tr>
<th valign=top align=right> Date Assigned: </th>
<td valign=top>
[util_AnsiDatetoPrettyDate $date_assigned]
</td>
</tr>

<tr>
<th valign=top align=right>Will this project<br>be graded? </th>
<td valign=top>
[util_PrettyBoolean $requires_grade_p]
</td>
</tr>

<tr>
<th valign=top align=right> Fraction of Final Grade: </th>
<td valign=top>"

if {[empty_string_p $weight]} {
    append return_string "N/A"
} else {
    append return_string "$weight"
}

append return_string "
</td>
</tr>
<tr>
<th align=right>Grade Group</th>
<td>"

if {![empty_string_p $grade_id]} {
    set selection [ns_db 0or1row $db "select grade_name, weight from edu_grades where grade_id = $grade_id"]
} else {
    set selection ""
}


if {$selection!=""} {
    set_variables_after_query
} else {
    set grade_name ""
    set weight ""
}

append return_string "
[edu_maybe_display_text $grade_name] [ec_decode $weight "" "" "- $weight %"]
</td></tr>
<tr>
<th valign=top align=right>
Will students submit <br>
answers electronically?
</th>
<td valign=top>
[util_PrettyBoolean $electronic_submission_p]
</td>
</tr>

<tr>
<th valign=top align=right> Assigned By: </th>
<td valign=top>
$first_names $last_name
</td>
</tr>

<tr>
<th valign=top align=right> Last Modified: </th>
<td valign=top>
[util_AnsiDatetoPrettyDate $last_modified]
</td>
</tr>


</table>
<br>
"
set task_type project
set task_id $project_id

if {![empty_string_p $file_id]} {
    append return_string "<a href=\"../task-edit.tcl?task_id=$task_id&task_type=$task_type\">Edit $project_name</a> | <a href=[edu_url]class/admin/task-file-new.tcl?[export_url_vars return_url task_id task_type]>Upload new version</a>"
} else {
    append return_string "<a href=\"task-edit.tcl?task_id=$task_id&task_type=$task_type\">Edit $project_name</a> | <a href=[edu_url]class/admin/task-file-new.tcl?[export_url_vars return_url task_id task_type]>Upload associated file</a>"
}



##############################################
#                                            #
#  We are now going to list the students     #
#  that have and have not been evaluated for #
#  the given project                         #
#                                            #
##############################################


append return_string "
<h3>Project Instances</h3>
<ul>
"

set selection [ns_db select $db "select project_instance_id, project_instance_name, project_instance_url, description from edu_project_instances where project_id = $task_id and active_p = 't'"] 

set n_project_instances 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "<li><a href=\"instance-info.tcl?project_instance_id=$project_instance_id\">$project_instance_name</a>"

    if {![empty_string_p $url]} {
	append return_string "&nbsp (<a href=\"$url\">$url</a>)"
    }

    incr n_project_instances
}

if {$n_project_instances == 0} {
    append return_string "There are not currently any projects being worked on.<br><Br>"
} else {
    append return_string "<p>"
}

append return_string "
<li><a href=\"instance-add.tcl?project_id=$project_id\">Add a project instance</a>
</ul>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string







