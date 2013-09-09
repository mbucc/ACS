ad_page_contract {
    @cvs-id member-add-3.tcl,v 3.3.2.7 2000/08/02 17:14:21 bryanche Exp
    @param group_id The ID of the group being worked on
    @param user_id_from_search The user ID from user searching
    @param role The role of the new user
    @param return_url The URL return to when finished
    @param new_role The new role of the already-a-member user
    @param existing_role The current role of the already-a-member user
} {
    group_id:notnull,naturalnum
    user_id_from_search:notnull,naturalnum
    {role ""}
    {existing_role ""}
    {new_role ""}
    {return_url "group?group_id=$group_id"}
}

set mapping_user [ad_get_user_id]

set mapping_ip_address [ns_conn peeraddr]

if { ![info exists role] || [empty_string_p $role] } {
    # we weren't just given a role so let's look at the user's choice
    if { [info exists existing_role] && ![empty_string_p $existing_role] } {
	set role $existing_role
    } elseif { [info exists new_role] && ![empty_string_p $new_role] } {
	set role $new_role
    } else {
	ad_return_error "No role specified" "We couldn't figure out what role this new member is supposed to have; either you didn't choose one or there is a bug in our software."
	return
    }
}

#make sure this user doesn't already have this role
set ug_role_check [db_string ug_sel_role_ck "select count(*)
from user_group_map
where user_id = :user_id_from_search
and group_id = :group_id
and role = :role"]

if {$ug_role_check > 0} {
    ad_return_warning "User Already has Role" "
    [db_string ug_sel_role_names "select first_names || ' ' || last_name
    from users where user_id = :user_id_from_search"]
    user already
    has the role of <i>$role</i>."
    return
}

db_transaction {
    ns_log Notice "bq: role of $role; exist $existing_role"
    db_dml ug_insert_user "insert into user_group_map (group_id, user_id, role, mapping_user, mapping_ip_address) 
                   select :group_id, :user_id_from_search, :role, :mapping_user, :mapping_ip_address from dual"
    # Extra fields
    set sql "select field_name from all_member_fields_for_group where group_id = :group_id"
    
    db_foreach all_field_name $sql {
	if { [exists_and_not_null $field_name] } {
	    set value_of_field_name [set $field_name]
	    ns_log Notice "filed_name: $field_name ; value_of: $value_of_field_name"
	    db_dml user_insert "insert into user_group_member_field_map
	    (group_id, user_id, field_name, field_value)
	    values (:group_id, :user_id_from_search, :field_name, :value_of_field_name)"
	}
    }
} on_error {
    ad_return_error "Database Error" "Error while trying to insert user into a user group.

    Database error message was:	
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>	
    
    [ad_admin_footer]"
    return
}

ad_returnredirect $return_url
