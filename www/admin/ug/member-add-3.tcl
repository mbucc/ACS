# $Id: member-add-3.tcl,v 3.1.2.1 2000/04/28 15:09:33 carsten Exp $
set_the_usual_form_variables

# group_id, user_id_from_search, one or more of role, existing_role, new_role
# all the info for extra member fields
# Maybe return_url

set dbs [ns_db gethandle main 2]
set db [lindex $dbs 0]
set sub_db [lindex $dbs 1]

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

    
with_transaction $db {


    ns_db dml $db "insert into user_group_map (group_id, user_id, role, mapping_user, mapping_ip_address) select $group_id, $user_id_from_search, '[DoubleApos $role]', $mapping_user, '$mapping_ip_address' from dual"
  
    # Extra fields
    set sub_selection [ns_db select $sub_db "select field_name from all_member_fields_for_group where group_id = $group_id"]
    while { [ns_db getrow $sub_db $sub_selection] } {
	set_variables_after_subquery
	if { [exists_and_not_null $field_name] } {
	    ns_db dml $db "insert into user_group_member_field_map
(group_id, user_id, field_name, field_value)
values ($group_id, $user_id_from_search, '[DoubleApos $field_name]', [ns_dbquotevalue [set $field_name]])"
        }
    }
    
} {
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

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "group.tcl?group_id=$group_id"
}
