# $Id: members.tcl,v 3.1.2.1 2000/04/11 11:57:08 carsten Exp $
# File:     /groups/admin/group/members.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  groups members and privileges administration page
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


set selection [ns_db 1row $db "
select ug.approved_p, ug.creation_user, ug.registration_date, ug.group_name,
       ug.new_member_policy,ug.spam_policy, ug.email_alert_p, ug.group_type, 
       ug.multi_role_p, ug.group_admin_permissions_p,
       first_names, last_name
from user_groups ug, users u
where ug.group_id = $group_id
and ug.creation_user = u.user_id"]
set_variables_after_query

ReturnHeaders 

ns_write "
[ad_scope_admin_header "Membership Administration" $db]
[ad_scope_admin_page_title "Membership Administration" $db]
[ad_scope_admin_context_bar "Membership Admin"]
<hr>
"

append html "
<h3>Membership</h3>
<form action=new-member-policy-update.tcl method=post>
<ul>
<li>New Member Policy: 
<select name=new_member_policy>
[ad_generic_optionlist { open wait closed }  { open wait closed } $new_member_policy]
</select>
<input type=submit name=submit value=\"Edit\">
</form>

<li>Send email to admins on new membership request:  [util_PrettyBoolean $email_alert_p] (<a href=\"email-alert-policy-update.tcl\">Toggle</a>)
<p>
</ul>
"

set selection [ns_db select $db "
select queue.user_id, first_names || ' ' || last_name as name, to_char(queue_date, 'Mon-dd-yyyy') as queue_date
from user_group_map_queue queue, users 
where queue.user_id = users.user_id
and group_id = $group_id
order by queue_date asc
"]


set counter 0
while { [ns_db getrow $db $selection] } {
    if { $counter== 0 } {
	append html "
	<h3>Users who have asked for membership</h3>
	<ul>"
    }
    set_variables_after_query
    incr counter
    append html "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$name</a> - $queue_date\n  &nbsp <a href=\"membership-grant.tcl?[export_url_vars user_id]\"> <font color=red>(grant membership)</font></a> &nbsp; | &nbsp;  <a href=\"membership-refuse.tcl?[export_url_vars user_id]\"><font color=red>(refuse membership)</font></a>"
}

if { $counter!= 0 } {
    append html "</ul>"
}

append html "
<h3>Administrator Members</h3>

<ul>
"

# let's look for administrators

set selection [ns_db select $db "
select user_id, first_names || ' ' || last_name as name
from users
where ad_user_has_role_p ( user_id, $group_id, 'administrator' ) = 't'"]

set counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    append html "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$name</a>  &nbsp; &nbsp <a href=\"role-edit.tcl?[export_url_vars user_id]\">edit role</a> | <a href=\"member-remove.tcl?[export_url_vars user_id]\">remove</a> \n"
}

if { $counter== 0 } {
    append html "no administrators are currently defined for this group"
}

append html "
<p>
<li><a href=\"member-add.tcl?role=administrator\">add an administrator</a>
</ul>

<h3>Other Members</h3>

<ul>
"

# let's look for members

set selection [ns_db select $db "
select map.user_id, map.role, first_names || ' ' || last_name as name
from user_group_map map, users 
where map.user_id = users.user_id
and group_id = $group_id
and role <> 'administrator'
order by role, name"]

set counter 0
set last_role ""
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter
    if { $role != $last_role } {
	set last_role $role
	append html "<h4>$role</h4>"
    }
    append html "<li><a href=\"/shared/community-member.tcl?user_id=$user_id\">$name</a> &nbsp; &nbsp <a href=\"role-edit.tcl?[export_url_vars user_id]\">edit role</a> | <a href=\"member-remove.tcl?[export_url_vars user_id]\">remove</a>\n"
}

if { $counter== 0 } {
    append html "no members found"
}

append html "
<p>
<li><a href=\"member-add.tcl?role=member\">add a member</a>
</ul>"


if { [string compare $multi_role_p "t"] == 0} {
    append html "
    <h3>Permissions</h3>
    Note: users with the role administrator have full authorization.
    <p>
    "


    append role_table_title "
    <table border=1 cellpadding=2><tr><th>Role \\\\ Action</th>"
    set actions_list [database_to_tcl_list $db "select action from user_group_actions where group_id = $group_id"]
    set roles_list [database_to_tcl_list $db "select role from user_group_roles where group_id = $group_id"]
  
    
    append role_table "<tr>"

    set actions_with_mapping ""

    foreach role $roles_list {
	set allowed_actions_for_role [database_to_tcl_list $db "select action from user_group_action_role_map where group_id = $group_id and role='[DoubleApos $role]'"]
	append role_table "<tr><th align=left>$role</th>"
	foreach action $actions_list {
	    if {[lsearch $allowed_actions_for_role $action] == -1} {
		set state "Denied"
	    } else {
		set state "Allowed"
	   }
	   
	   if {[lsearch $state "Denied"] == 0  && [string compare $group_admin_permissions_p "f"] != 0 } {
	       append role_table "<td><a href=\"action-role-map.tcl?[export_url_vars action role]\">$state</a></td>"
	   } elseif { [string compare $group_admin_permissions_p "f"] != 0 } {
	       lappend actions_with_mapping $action
	       append role_table "<td><a href=\"action-role-unmap.tcl?[export_url_vars action role]\">$state</a></td>"
	   } else {
	       lappend actions_with_mapping $action
	       append role_table "<td>$state</td>"
	   }
       }
       append role_table "</tr>"
    }

    append role_table "
    </table>"

    foreach action $actions_list {
	append role_table_title "<th>$action</th>"
    }
    
    append role_table_title "</tr>"
    
    append html "
    $role_table_title
    $role_table
    <p>
    "
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_scope_admin_footer] 
"
