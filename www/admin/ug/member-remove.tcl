ad_page_contract {
    @param group_id the Id of the group
    @param user_id the user_id to remove
    @param role role of that user

    @cvs-id member-remove.tcl,v 3.3.2.6 2000/09/22 01:36:16 kevin Exp
} {
    group_id:notnull,naturalnum
    user_id:notnull,naturalnum
    role:notnull
}



if { [db_0or1row  get_user_info "
    select 
        first_names || ' ' || last_name as name, 
        group_name
    from 
        users, 
        user_group_map, 
        user_groups 
    where 
       users.user_id = :user_id
       and user_group_map.user_id = users.user_id
       and user_groups.group_id = user_group_map.group_id
       and user_group_map.group_id = :group_id and
       user_group_map.role = :role
"] == 0 } {


doc_return  200 text/html  "
[ad_admin_header "User could not be found in the specified role."]
<h2>User could not be found in the specified role.</h2>
<hr>
The user could not be removed from the role because he or she is no longer in it.
[ad_admin_footer]
"
return

}


doc_return  200 text/html "[ad_admin_header "Really remove $name from the role \"$role?\""]

<h2>Remove $name from the role \"$role\"</h2>

in <a href=\"group?[export_url_vars group_id]\">$group_name</a>

<hr>

<center>
<table>
<tr><td>
<form method=get action=\"group\">
[export_form_vars group_id]
<input type=submit name=submit value=\"No, Cancel\">
</form>
</td><td>
<form method=get action=\"member-remove-2\">
[export_form_vars group_id user_id role]
<input type=submit name=submit value=\"Yes, Proceed\">
</form>
</td></tr>
</table>
</center>
[ad_admin_footer]
"
