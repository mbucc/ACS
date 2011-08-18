# $Id: member-remove.tcl,v 3.1 2000/02/26 07:29:11 markc Exp $
set_the_usual_form_variables
  
# group_id, user_id, role

set db [ns_db gethandle]


set selection [ns_db 0or1row  $db "
    select 
        first_names || ' ' || last_name as name, 
        group_name
    from 
        users, 
        user_group_map, 
        user_groups 
    where 
       users.user_id = $user_id
       and user_group_map.user_id = users.user_id
       and user_groups.group_id = user_group_map.group_id
       and user_group_map.group_id = $group_id and
       user_group_map.role = '$role'
"]


ReturnHeaders 

if { $selection == "" } {
ns_write "
[ad_admin_header "User could not be found in the specified role."]
<h2>User could not be found in the specified role.</h2>
<hr>
The user could not be removed from the role because he or she is no longer in it.
[ad_admin_footer]
"
return

}
set_variables_after_query

ns_write "[ad_admin_header "Really remove $name from the role \"$role?\""]

<h2>Remove $name from the role \"$role\"</h2>

in <a href=\"group.tcl?[export_url_vars group_id]\">$group_name</a>

<hr>

<center>
<table>
<tr><td>
<form method=get action=\"group.tcl\">
[export_form_vars group_id]
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"member-remove-2.tcl\">
[export_form_vars group_id user_id role]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
</center>
[ad_admin_footer]
"
