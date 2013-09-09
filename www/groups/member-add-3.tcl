ad_page_contract {
    
    Add a new member to a group with additional fields if needed.

    @param group_id the group ID
    @param user_id_from_search the user ID obtained from a search
    @param role the role of the user
    @param return_url where to send the user afterwards
    @param extra An array of additional elements to include in the user information.

    @cvs-id member-add-3.tcl,v 3.4.6.6 2001/01/10 21:23:50 khy Exp
} {
    group_id:notnull,naturalnum
    user_id_from_search:notnull,naturalnum
    role:optional
    return_url:optional
    extra:array,optional
}

# lars@pinds.com, March 17, 2000:
# Put in a hack so intranet modules will work as expected but without the security hole.
# We shouldn't have module-specific code here, though, so we should definitely find
# a better solution for next release.

set user_id [ad_verify_and_get_user_id]

if { ![db_0or1row {
    select group_type, new_member_policy 
    from user_groups 
    where group_id=:group_id
}] } {
    ad_return_error "Couldn't find group" "We couldn't find the group $group_id. Must be a programming error."
    return
}

ad_return_complaint 1 "<li> problem"
return

if { ![ad_administrator_p  $user_id] } {

    if { ![ad_user_group_authorized_admin $user_id $group_id ] } {

	set intranet_administrator_p [ad_administration_group_member  [ad_parameter IntranetGroupType intranet] "" $user_id]

	if { $group_type != "intranet" || !$intranet_administrator_p } {

	    if { $new_member_policy != "open" } {
		
		ad_return_complaint 1 "<li>The group you are attempting to add a member to 
		does not have an open new member policy."
		return
	    }
	}
    }
}

set mapping_user [ad_get_user_id]
set mapping_ip_address [ns_conn peeraddr]

if ![info exists role] {
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

db_transaction {

    db_dml user_group_delete {
	delete from user_group_map 
	where group_id = :group_id 
	and user_id = :user_id_from_search
    }

    db_dml user_group_insert "
	insert into user_group_map (group_id, user_id, role, mapping_user, mapping_ip_address) 
	select $group_id, $user_id_from_search, '[db_quote $role]', $mapping_user, 
    '$mapping_ip_address' from dual 
    where ad_user_has_role_p ( :user_id_from_search, :group_id, :role ) <> 't'"
    
    # Extra fields

    db_foreach extra_fields_process {
	select field_name from all_member_fields_for_group where group_id = :group_id
    } {

	if { [info exists extra($field_name)] && ![empty_string_p $extra($field_name)] } {
	    set field_value $extra($field_name)
	    db_dml user_extra_field_insert {
		insert into user_group_member_field_map
		(group_id, user_id, field_name, field_value)
		values (:group_id, :user_id_from_search, :field_name, :field_value)
	    }
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
	
[ad_footer]"
    return
}


if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "group?group_id=$group_id"
}

