# $Id: member-remove.tcl,v 3.0.4.1 2000/04/28 15:11:00 carsten Exp $
# File: /groups/group/member-remove.tcl
# Date: mid-1998
# Contact: teadams@arsdigita.com, tarik@arsdigita.com
# Purpose: removes the mebmer from the group
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set group_name [ns_set get $group_vars_set group_name]
set group_public_url [ns_set get $group_vars_set group_public_url]

set user_id [ad_get_user_id]

if {$user_id == 0} {
   ad_returnredirect "/register.tcl?return_url=[ad_urlencode $group_public_url/member-remove.tcl]"
    return
}

set db [ns_db gethandle]

ns_db dml $db "
delete from user_group_map where group_id = $group_id and user_id = $user_id
"

ns_return 200 text/html "
[ad_scope_header "Success" $db]

<h2>Success</h2>

removing you from <a href=\"$group_public_url/\">$group_name</a>

<hr>

There isn't much more to say.  You can return now 
to [ad_pvt_home_link]

[ad_scope_footer]
"
