ad_page_contract {
    @param group_id The ID of the group to get data on

    @cvs-id group.tcl,v 3.5.2.16 2000/12/16 01:51:43 cnk Exp
} {
    group_id:notnull,naturalnum
}

ad_maybe_redirect_for_registration
set user_id [ad_get_user_id]

set user_group_exists_p [db_0or1row user_group_properites  {
    select ug.group_type, ug.group_name, ug.short_name, ug.approved_p, ug.existence_public_p, ug.spam_policy, ug.new_member_policy, ug.registration_date, ug.creation_user, ug.multi_role_p, ug.email_alert_p, ug.group_admin_permissions_p, first_names, last_name, 
    parent_group_id, user_group_name_from_id(parent_group_id) as parent_group_name
    from user_groups ug, users u
    where group_id = :group_id
    and ug.creation_user = u.user_id
}]

if {!$user_group_exists_p} {
    ad_return_error "Group doesn't exists" "The specified group doesn't exist. Please back up to select a new group"
    return
}

set page_content ""

if { [empty_string_p $parent_group_id] } {
    set context_bar [ad_admin_context_bar [list "index" "User Groups"] [list "group-type?[export_url_vars group_type]" "One Group Type"] "One Group"]
} else {
    set context_bar [ad_admin_context_bar [list "index" "User Groups"] [list "group-type?[export_url_vars group_type]" "One Group Type"] [list group?group_id=$parent_group_id "One Group"] "One Subgroup"]

}

append page_content "
[ad_admin_header $group_name]
<h2>$group_name</h2>
$context_bar
<hr>
"

if { $approved_p == "f" } {
    append properties_html "
    <blockquote>
    <font color=red>this group is awaiting approval</font>
    (<a href=\"approved-p-toggle?group_id=$group_id\">approve right now</a>)
    </blockquote>
    "
}

append properties_html "
<ul>
<li>Group name:  $group_name (<a href=\"group-name-edit?group_id=$group_id\">edit</a>)
<li>Group short name:  $short_name (<a href=\"group-shortname-edit?group_id=$group_id\">edit</a>)
<li>Group type:  <a href=\"group-type?[export_url_vars group_type]\">$group_type</a>
<li>Existence Public?  <a href=\"existence-public-p-toggle?group_id=$group_id\">[util_PrettyBoolean $existence_public_p]</a>
"

set subgroup_html ""
if { ![empty_string_p $parent_group_id] } {
    append properties_html "  <li> Parent group: <a href=group?group_id=$parent_group_id>$parent_group_name</a>\n"
} else {
    # Look for subgroups since this group isn't a subgroup
    if { [empty_string_p $parent_group_id] } {
	set subgroup_html "
<h3>Subgroups</h3>
<ul>
"

        db_foreach user_group_subgroups {
	    select ug.group_id as subgroup_id, group_name as subgroup_name, ug.registration_date, 
	    ug.approved_p, count(user_id) as n_members
	    from user_groups ug, user_group_map ugm
	    where parent_group_id=:group_id
	    and ug.group_id=ugm.group_id(+)
	    group by ug.group_id, group_name, ug.registration_date, ug.approved_p
	    order by upper(group_name)
	} {
	    set num_members "$n_members [util_decode $n_members 1 member members]"
	    append subgroup_html "  <li> <a href=group?group_id=$subgroup_id>$subgroup_name</a> ($num_members)\n"
	} if_no_rows {
	    append subgroup_html "  <li> There are no subgroups\n"
	}
    
	set return_url "/admin/ug/group?[export_url_vars group_id]"
	append subgroup_html "  <p><li> <a href=/groups/group-new-2?parent_group_id=$group_id&[export_url_vars group_type return_url]>add a subgroup</a>
	</ul>
	"
    }
}

append page_content "
<p>

<li>Created by <a href=\"/shared/community-member?user_id=$creation_user\">$first_names $last_name</a> on [util_AnsiDatetoPrettyDate $registration_date]

<li><form action=new-member-policy-update method=post>
New Member Policy: <select name=new_member_policy>[ad_generic_optionlist { open wait closed }  { open wait closed } $new_member_policy]
</select>
[export_form_vars group_id]
<input type=submit name=submit value=\"Edit\">
<p>
</form>

<li><form action=spam-policy-update method=post>
Group Spam Policy: 
<select name=spam_policy>
[ad_generic_optionlist { open wait closed }  { open wait closed } $spam_policy]
</select>
[export_form_vars group_id]
<input type=submit name=submit value=\"Edit\">
<p>
</form>

<li>Send email to admins on new membership request: [util_PrettyBoolean $email_alert_p]
(<a href=\"admin-email-alert-policy-update?[export_url_vars group_id]\">Toggle</a>)
<p>

<li>Use the multi-role permission system: [util_PrettyBoolean $multi_role_p]
(<a href=\"multi-role-p-toggle?[export_url_vars group_id]\">Toggle</a>)
<p>
"

# determine if there are any special helper tables
set li_edit_link ""
set info_table_name [string toupper [ad_generate_helper_table_name $group_type]]
set selection [ns_set create]


if { [db_string user_group_info_table_exists {
    select count(*) from user_tables 
    where table_name=:info_table_name
}]  > 0 } {
    set supplemental_col_list [list]
    db_foreach group_columns "select column_name from user_group_type_fields where group_type = :group_type order by sort_key" {
	lappend supplemental_col_list $column_name
    }

    if { [llength $supplemental_col_list] == 0 } {
	append properties_html "<P><li>we have no supplemental information on this group"
    } elseif { ![db_0or1row select_supplemental_group_info "
	    select [join $supplemental_col_list ", "]
	    from $info_table_name 
	    where group_id = :group_id
	    "  -column_set selection] } {
	# there is suplemental info for this group type now - but not for this group (no row in ${group_type}_info table
	foreach column_name $supplemental_col_list {
	    append properties_html "<li>$column_name - not collected \n"
	}
	set li_edit_link "<li><a href=\"group-info-edit?[export_url_vars group_id]\">Edit</a>"
    } else {
	set set_variables_after_query_i 0
	set set_variables_after_query_limit [ns_set size $selection]
	while {$set_variables_after_query_i < $set_variables_after_query_limit} {
	    append properties_html "<li>[ns_set key $selection $set_variables_after_query_i]: [ns_set value $selection $set_variables_after_query_i]\n"
	    incr set_variables_after_query_i
	}
	set li_edit_link "<li><a href=\"group-info-edit?[export_url_vars group_id]\">Edit</a>"
    }

} else {
    append properties_html "<P><li>we have no supplemental information on this group"
}

append properties_html "
<p>
$li_edit_link
<li><a href=\"/admin/users/action-choose?[export_url_vars group_id]\">Download or spam members</a>
</ul>
"
append page_content $properties_html

set module_available_p [db_string user_group_module_available_p {
    select count(*)
    from acs_modules
    where supports_scoping_p='t'
    and module_key not in (select module_key
			   from content_sections
			   where scope='group' and group_id=:group_id
			   and (section_type='system' or section_type='admin'))
}]

set modules_table_html ""

set group_module_administration [db_string user_group_module_adminstration {
    select group_module_administration 
    from user_group_types 
    where group_type=user_group_group_type(:group_id)
}]

db_foreach user_group_modules {
    select module_key, pretty_name_from_module_key(module_key) as module_pretty_name
    from content_sections
    where scope='group' and group_id=:group_id and (section_type='system' or section_type='admin')
} {

    if { [string compare $group_module_administration full]==0 } {
	append modules_table_html "
	<tr>
	<td>$module_pretty_name
	<td>[ad_space 2]<a href=\"group-module-remove?[export_url_vars group_id module_key]\">remove</a>
	</tr>
	"
    } else {
	append modules_table_html "
	<tr>
        <td>$module_pretty_name
        </tr>
	"
    }
} if_no_rows {
	append modules_table_html "
	<tr><td>no modules are associated with this group</tr>
	"
}
    
append modules_html "
<h3>Modules associated with groups in $group_name</h3>
<ul>
<table>
$modules_table_html
</table>
<p>
"
if { $module_available_p } { 
    append modules_html "
    <li><a href=\"group-module-add?[export_url_vars group_id]\">add module</a>
    "
} else {
    append modules_html "This group has [ad_decode $group_module_administration enabling "only enabling/disabling" "no"] module administration privileges.
    Modules can be added to  or removed from the group only on the group type level."

}

append modules_html "
</ul>
"
append page_content $modules_html

append group_type_fields_html "
<h3>Member Fields From Group Type</h3>

<ul>
"



db_foreach user_group_type_member_fields {
    select field_name, field_type
    from user_group_type_member_fields
    where group_type = :group_type
    order by sort_key
} {
    append group_type_fields_html "<li>$field_name ($field_type)\n"
}

append group_type_fields_html "<p>
<p>

<li>go to the user group type page to <a href=\"group-type?[export_url_vars group_type]\">edit</a>
</ul>
"

append page_content $group_type_fields_html

append group_fields_html "
<h3>Member Fields From Group</h3>

<table border=0 width=80%>
"

set number_of_fields [db_string user_group_type_number_of_fields "select count(*) from user_group_member_fields where group_id = :group_id"]

set counter 0

db_foreach user_group_member_fields {
    select field_name, field_type, sort_key
    from user_group_member_fields
    where group_id = :group_id
    order by sort_key
} {
    incr counter
    if { $counter == $number_of_fields } {
	append group_fields_html "<tr><td>$field_name ($field_type)<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"group-member-field-add?group_id=$group_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;\]</font>\n"
    } else {
	append group_fields_html "<tr><td>$field_name ($field_type)<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"group-member-field-add?group_id=$group_id&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"group-member-field-swap?group_id=$group_id&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;\]</font>\n"
    }   
} if_no_rows {
    
    append group_fields_html "<tr><td>No group-specific member data currently collected.
<p>
<ul>
<li><a href=group-member-field-add?[export_url_vars group_id]>add a field</a>
</ul>"
}

append group_fields_html "</table>\n"

append page_content $group_fields_html

set counter 0
db_foreach user_group_member_queue "select queue.user_id, first_names || ' ' || last_name as name, to_char(queue_date, 'Mon-dd-yyyy') as queue_date
from user_group_map_queue queue, users 
where queue.user_id = users.user_id
and group_id = :group_id
order by queue_date asc" {
    if { $counter == 0 } {
	append members_html "<h3>Users who have asked for membership</h3>
	<ul>"
    }

    incr counter
    append members_html "<li><a href=\"/admin/users/one?user_id=$user_id\">$name</a> - $queue_date\n <A href=\"membership-grant?[export_url_vars user_id group_id]\"> &nbsp; <font color=red>(grant membership)</font></a> &nbsp; | &nbsp;  <A href=\"membership-refuse?[export_url_vars user_id group_id]\"><font color=red>(refuse membership)</font></a>"
}

if { $counter != 0 } {
    append members_html "</ul>"
}

append members_html "
$subgroup_html

"

append members_html "
<h3>Group Members</h3>
<ul>
"

# let's look for members


set counter 0
set last_role ""

db_foreach user_group_members {
    select map.user_id, map.role, first_names || ' ' || last_name as name
    from user_group_map map, users 
    where map.user_id = users.user_id
    and group_id = :group_id
    order by role, last_name, first_names
} {
    incr counter
    if { $role != $last_role } {
	set last_role $role
	append members_html "<h4>Role: $role</h4>"
    }
    append members_html "<li><a href=\"/admin/users/one?user_id=$user_id\">$name</a> &nbsp; &nbsp | <a href=\"member-remove?[export_url_vars user_id group_id role]\">remove</a>\n"
} if_no_rows {
    append members_html "no members found"
}

append members_html "
<p>
<li><a href=\"member-add?group_id=$group_id&return_url=[ns_urlencode group?group_id=$group_id]\">add a member in a role</a>
</ul>"

append page_content $members_html

if { [string compare $multi_role_p "t"] == 0} {
    append permissions_html "
    <h3>Permissions</h3>
    Note: users with the role \"administrator\" have full authorization.
    <p>"

    append role_table_title "<table border=1 cellpadding=2><tr><th>Role \\\\ Action</th>"
    set actions_list [db_list user_group_actions "select action from user_group_actions where group_id = :group_id"]
    set roles_list [db_list user_group_roles "select role from user_group_roles where group_id = :group_id"]
  
   append role_table "<tr>"

   set actions_with_mapping ""

   foreach role $roles_list {
       set allowed_actions_for_role [db_list user_group_action_for_role {
	   select action 
	   from user_group_action_role_map 
	   where group_id = :group_id and role=:role
       }]
       if { [string compare [llength $allowed_actions_for_role] 0 ] == 0 } { 
	   append role_table "<tr><th align=left>$role (<a href=\"role-delete?[export_url_vars group_id role]\">delete</a>)</th>"
       } else {
	   append role_table "<tr><th align=left>$role</th>"
       }
       foreach action $actions_list {
	   if {[lsearch $allowed_actions_for_role $action] == -1} {
	       append role_table "<td><a href=\"action-role-map?[export_url_vars action role group_id]\">Denied</a></td>"
	   } else {
	       lappend actions_with_mapping $action
	       append role_table "<td><a href=\"action-role-unmap?[export_url_vars action role group_id]\">Allowed</a></td>"
	   }
       }
       append role_table "</tr>"
    }

    append role_table "
    </table>"

    foreach action $actions_list {
	if {[lsearch $actions_with_mapping $action] == -1 } {
	    append role_table_title "<th>$action (<a href=\"action-delete?[export_url_vars action group_id]\">delete</a>)</th>"
	} else {
	    append role_table_title "<th>$action</th>"
	}
    }
    
    append role_table_title "</tr>"

    append permissions_html "
    $role_table_title
    $role_table
    <p>
    <form action=role-add method=post>
    [export_form_vars group_id]
    Add a role: <input text=text maxlength=200 name=role>
    <input type=submit name=submit value=\"Submit\">
    </form>
    <p>
    <form action=action-add method=post>
    Add an action: <input text=text maxlength=200 name=action>
    [export_form_vars group_id]
    <input type=submit name=submit value=\"Submit\">
    </form>
    </ul>
    <p>
    Can group administrators control permission information? [util_PrettyBoolean $group_admin_permissions_p] (<a href=\"group-admin-permissions-toggle?group_id=$group_id\">Toggle</a>)
    "
    
    append page_content $permissions_html
}

append extreme_html "
<h3>Extreme Actions</h3>

<blockquote>
<form method=GET action=\"group-delete\">

[export_form_vars group_id]
<input type=submit value=\"Delete This Group\">
</form>
</blockquote>"

append page_content "
$extreme_html
[ad_admin_footer]
"

doc_return  200 text/html $page_content
