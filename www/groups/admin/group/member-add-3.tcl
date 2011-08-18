# $Id: member-add-3.tcl,v 3.1.2.1 2000/04/28 15:10:57 carsten Exp $
# File:     /groups/admin/group/member-add-3.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  add a member to the user group
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# user_id_from_search, one or more of role, existing_role, new_role

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return

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

# now the unique constraint is on user_id, group_id, role,
# not just on user_id, group_id; this means we can insert
# multiple instances of this user into this group, but with
# different roles
ns_db dml $db "
insert into user_group_map
(group_id, user_id, role, mapping_user, mapping_ip_address)
     select $group_id,
            $user_id_from_search,
            '[DoubleApos $role]',
            $mapping_user,
            '$mapping_ip_address'
       from dual
      where not exists (select user_id
                          from user_group_map
                         where group_id = $group_id
                           and user_id = $user_id_from_search
                           and role = '[DoubleApos $role]')"

ad_returnredirect members.tcl


