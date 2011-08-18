#
# /www/education/class/admin/users/student-info-edit.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page allows the admin to edit the student's information
#

ad_page_variables {
    student_id
}


set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set selection [ns_db 0or1row $db "select first_names, 
         last_name, 
         email as student_email,
         map.role,
         pretty_role,
         pretty_role_plural
    from users, 
         user_group_map map,
         edu_role_pretty_role_map role_map
   where users.user_id = $student_id 
     and users.user_id = map.user_id 
     and role_map.group_id = map.group_id
     and lower(role_map.role) = lower(map.role)
     and lower(role_map.role) = lower('[edu_get_student_role_string]')
     and map.group_id=$class_id"]


if {$selection == ""} {
    ad_return_complaint 1 "<li>You must call this page with a valid user id"
    return
} else {
    set_variables_after_query
}


set institution_id [database_to_tcl_string_or_null $db "select field_value from user_group_member_field_map where user_id = $student_id and group_id = $class_id and field_name = 'Institution ID'"]

set student_account [database_to_tcl_string_or_null $db "select field_value from user_group_member_field_map where user_id = $student_id and group_id = $class_id and field_name = 'Student Account'"]


append return_string "
[ad_header "$pretty_role Info @ [ad_system_name]"]

<h2>$first_names $last_name</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "students-view.tcl" "$pretty_role_plural"] "One $pretty_role"]

<hr>
<blockquote>

<form method=post action=\"student-info-edit-2.tcl\">

[export_form_vars student_id]

<table>

<tr>
<th>
Identification Number:
</td>

<td>
<input type=input size=20 maxsize=100 name=institution_id value=\"[philg_quote_double_quotes $institution_id]\">
</td>
</tr>

<tr>
<th>
Account Number:
</td>

<td>
<input type=input size=20 maxsize=100 name=student_account value=\"[philg_quote_double_quotes $student_account]\">
</td>
</tr>

<tr>
<td colspan=2 align=center>
<br>
<input type=submit value=\"Edit $pretty_role Information\">
</td>
</tr>
</table>

</form>
</blockquote>

[ad_footer]
"


ns_db releasehandle $db

ns_return 200 text/html $return_string







