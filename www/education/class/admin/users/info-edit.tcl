#
# /www/education/class/admin/users/info-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page lets the user review what is about to go into the database
#


# NOTE: every field mapped to user_id and class_id in 
# user_group_member_field_map will be wiped out and updated using this script!
# so be sure that all fields added to user_group_type_member_fields are 
# included in this edit form

ad_page_variables {
    user_id
}

set db_handles [edu_get_two_db_handles]
set db [lindex $db_handles 0]
set db_sub [lindex $db_handles 1]

set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Edit User Information</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Users] [list "one.tcl?user_id=$user_id" "One User"] "Edit"]

<hr>
<b>Note:</b> Not all fields are applicable to the user.
<p>
<blockquote>
<form method=post action=\"info-edit-2.tcl\">
<table>
"

set email [database_to_tcl_string $db "
select email from users where user_id=$user_id"]

append return_string "
<tr><th align=right>Email:</th>
<td>$email</td></tr>
"

set selection [ns_db select $db "
select distinct field_name, sort_key
from user_group_type_member_fields mf,
     user_group_map map
where map.user_id = $user_id
  and (mf.role is null or lower(mf.role) = lower(map.role))
  and map.group_id = $class_id
  and mf.group_type='edu_class'
order by sort_key"]

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    append return_string "
    <tr>
    <th align=right>$field_name</th>
    "

    set sub_selection [ns_db 0or1row $db_sub "select distinct field_value 
    from user_group_member_field_map
    where field_name='[DoubleApos $field_name]' 
    and user_id=$user_id
    and group_id=$class_id"]

    if {$sub_selection!=""} {
	set_variables_after_subquery
    } else {
	set field_value ""
    }
    
    append return_string "
    <td><input type=text size=40 value=\"$field_value\" name=\"$field_name\"></td>
    </tr>
    "
}

append return_string "
[export_form_vars user_id email]
<tr><th></th>
<td><input type=submit value=Edit></td>
</tr>
</table>
</blockquote>
</form>

[ad_footer]
"

ns_db releasehandle $db
ns_db releasehandle $db_sub

ns_return 200 text/html $return_string
