#
# /www/education/class/admin/projects/instance-add.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# this page allows users to add project instances. 
#

ad_page_variables {
    project_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Add Tasks"]
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

set student_pretty_role [database_to_tcl_string $db "select pretty_role from edu_role_pretty_role_map where lower(role) = lower('[edu_get_student_role_string]') and group_id = $class_id"]


set return_string "
[ad_header "One Project @ [ad_system_name]"]

<h2>Add a Project Instance</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" Administration] [list "" "View Projects"] "Add Project Instance"]

<hr>
for $project_name
<blockquote>

<form method=post action=\"instance-add-2.tcl\">
[export_form_vars project_id]
<table>

<tr>
<th align=right>
Name:
</td>
<td>
<input type=text size=30 name=project_instance_name>
</td>

<tr>
<th align=right>
URL:
</td>
<td>
<input type=text size=30 name=url value=\"http://\">
</td>

<tr>
<th align=right valign=top>
Description:
</td>
<td>
[edu_textarea description "" 50 6]
</td>

<tr>
<th align=right>
Project Type:
</th>
<td>
<input type=radio name=project_type value=user checked>
$student_pretty_role
[ad_space 4]
<input type=radio name=project_type value=team>
Team
</td>
</tr>

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







