# $Id: member-add-3.tcl,v 3.2.2.3 2000/04/28 15:10:56 carsten Exp $
set_the_usual_form_variables

# group_id, user_id_from_search, one or more of role, existing_role, new_role
# all the info for extra member fields
# Maybe return_url

set dbs [ns_db gethandle main 2]
set db [lindex $dbs 0]
set sub_db [lindex $dbs 1]

# ACK! Let's get some sanity checking in here. HUGE security hole. -jsc
validate_integer "user_id_from_search" $user_id_from_search
validate_integer "group_id" $group_id

#
# lars@pinds.com, March 17, 2000:
# Put in a hack so intranet modules will work as expected but without the security hole.
# We shouldn't have module-specific code here, though, so we should definitely find
# a better solution for next release.

set user_id [ad_verify_and_get_user_id]

set selection [ns_db 0or1row $db "select group_type, new_member_policy from user_groups where group_id=$group_id"]
if { [empty_string_p $selection] } {
    ad_return_error "Couoldn't find group" "We couldn't find the group $group_id. Must be a programming error."
    return
}
set_variables_after_query

if { ![ad_administrator_p $db $user_id] } {

    if { ![ad_user_group_authorized_admin $user_id $group_id $db] } {

	set intranet_administrator_p [ad_administration_group_member $db [ad_parameter IntranetGroupType intranet] "" $user_id]

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

with_transaction $db {

    ns_db dml $db "delete from user_group_map where group_id = $group_id and user_id = $user_id_from_search"

    ns_db dml $db "insert into user_group_map (group_id, user_id, role, mapping_user, mapping_ip_address) select $group_id, $user_id_from_search, '[DoubleApos $role]', $mapping_user, '$mapping_ip_address' from dual where ad_user_has_role_p ( $user_id_from_search, $group_id, '$role' ) <> 't'"
    
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
	
[ad_footer]"
    return
}

if { [exists_and_not_null return_url] } {
    ad_returnredirect $return_url
} else {
    ad_returnredirect "group.tcl?group_id=$group_id"
}
