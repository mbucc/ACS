# $Id: new-member-policy-update.tcl,v 3.1.2.1 2000/04/28 15:10:59 carsten Exp $
# File:    /groups/admin/group/new-member-policy-update.tcl
# Date:    mid-1998
# Contact: teadams@arsdigita.com, tarik@arsdigita.com
# Purpose: sets the new member policy for the group
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_form_variables
# new_member_policy

set db [ns_db gethandle]


if { [ad_user_group_authorized_admin [ad_verify_and_get_user_id] $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

ns_db dml $db "
update user_groups 
set new_member_policy = '$new_member_policy' 
where group_id = $group_id"

if { $new_member_policy == "open" } {
    # grant everyone in the queue membership
    
    ns_db dml $db "begin transaction"
    
    ns_db dml $db "
    insert into user_group_map 
    (user_id, group_id, mapping_ip_address,  role, mapping_user) 
    select user_id,
           group_id,
           ip_address,
           'member',
           [ad_get_user_id] 
      from user_group_map_queue 
     where group_id = $group_id 
       and not exists (select user_id 
                         from user_group_map 
                        where user_group_map.user_id = user_group_map_queue.user_id 
                          and group_id = $group_id
                          and role = 'member')"

    ns_db dml $db "
    delete from user_group_map_queue where group_id = $group_id"

    ns_db dml $db "end transaction"

}

ad_returnredirect members.tcl





