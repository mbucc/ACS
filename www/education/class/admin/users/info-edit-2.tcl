#
# /www/education/class/admin/users/info-edit-2.tcl
#
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#
# This page lets the user review what is about to go into the database
#

# user_id email field_names from user_group_type_member_fields for edu_class

set_the_usual_form_variables

set db [ns_db gethandle]
set id_list [edu_group_security_check $db edu_class "Manage Users"]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]

set return_string "
[ad_header "$class_name @ [ad_system_name]"]

<h2>Confirm User Information Edit</h2>

[ad_context_bar_ws_or_index [list "../../one.tcl" "$class_name Home"] [list "../" "Administration"] [list "" Users] [list "one.tcl?user_id=$user_id" "One User"] "Edit"]

<hr>
<b>Note:</b> Not all fields are applicable to the user.
<p>
<blockquote>
<form method=post action=\"info-edit-3.tcl\">
[export_entire_form]
<table>
<tr><th align=right>Email:</th>
<td>$email</td>
</tr>
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
    <td>[set $field_name]</td>
    </tr>
    "
}

append return_string "
<tr>
<th></th>
<td><input type=submit value=Confirm></td>
</tr>
</table>
</form>
</blockquote>
[ad_footer]
"

ns_db releasehandle $db

ns_return 200 text/html $return_string
