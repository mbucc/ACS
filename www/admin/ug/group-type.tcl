# $Id: group-type.tcl,v 3.0 2000/02/06 03:29:27 ron Exp $
# File:     /admin/ug/group-type.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  main page displaying information about the group type

set_the_usual_form_variables

# group_type

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select group_type, pretty_name as group_type_pretty_name, pretty_plural, approval_policy, default_new_member_policy,
       group_module_administration
from user_group_types where group_type = '$QQgroup_type'"]

set_variables_after_query

ReturnHeaders 

ns_write "
[ad_admin_header "$group_type_pretty_name"]
<h2>$group_type_pretty_name</h2>
[ad_admin_context_bar [list "index.tcl" "User Groups"] "One Group Type"]
<hr>
"

set n_members [database_to_tcl_string $db \
	"select count(1) from user_groups where group_type = '$QQgroup_type' and parent_group_id is null"]

if { $n_members == 0 } {
    append group_members_html "there are currently no user groups of this type"
} elseif { $n_members < 20 } {
    # let's just list them 
    set selection [ns_db select $db \
	    "select ug.group_id, ug.group_name, ug.registration_date, ug.approved_p, 
                    count(user_id) + user_groups_number_submembers(ug.group_id) as n_members,
                    user_groups_number_subgroups(ug.group_id) as n_subgroups
               from user_groups ug, user_group_map ugm
              where group_type = '$QQgroup_type'
                and ug.group_id = ugm.group_id(+)
                and parent_group_id is null
              group by ug.group_id, ug.group_name, ug.registration_date, ug.approved_p
              order by upper(group_name)"]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query
	set n_members "$n_members [util_decode $n_members 1 member members]"
	set n_subgroups "$n_subgroups [util_decode $n_subgroups 1 "subgroup" "subgroups"]"

	append group_members_html "<li><a href=\"group.tcl?group_id=$group_id\">$group_name</a> ($n_members, $n_subgroups)"
	if { $approved_p == "f" } {
	    append group_members_html " <font color=red>not approved</font>"
	}
	append group_members_html "\n"
    }
} else {
    append group_members_html "<li><a href=\"group-type-all-members.tcl?[export_url_vars group_type]\">show all $n_members</a>\n"
}

set return_url "/admin/ug/group-type.tcl?[export_url_vars group_type]"

append group_members_html "
<br>
<br>
<li><a href=\"[ug_url]/group-new-2.tcl?[export_url_vars group_type return_url]\">create a new $group_type_pretty_name</a>
</ul>
"

ns_write "
<h3>User groups in $group_type_pretty_name</h3>
<ul>
$group_members_html
</ul>
"

append properties_html "
<li>Pretty Name:  \"$group_type_pretty_name\" (plural: \"$pretty_plural\")
<li>Approval Policy (how new groups get created):  $approval_policy
<li>Default New Member Policy (how users will join groups of this type):  $default_new_member_policy
<li>Group Module Administration: 
    [ad_decode $group_module_administration full Complete enabling "Enabling/Disabling" none None undefined]
<br>
<br>
(<a href=\"group-type-edit.tcl?[export_url_vars group_type]\">edit</a>)
"

ns_write "
<h3>Properties of this type of group</h3>
<ul>
$properties_html
</ul>
"


set module_available_p [database_to_tcl_string $db "
select count(*)
from acs_modules
where supports_scoping_p='t'
and module_key not in (select module_key
                       from user_group_type_modules_map
                       where group_type='$QQgroup_type')"]



if { [string compare $group_module_administration enabling]==0 || \
	[string compare $group_module_administration none]==0 } {

    set selection [ns_db select $db "
    select ugtm.module_key, ugtm.group_type_module_id, am.pretty_name as module_pretty_name
    from user_group_type_modules_map ugtm, acs_modules am
    where ugtm.group_type='$QQgroup_type'
    and ugtm.module_key=am.module_key
    "]

    set module_counter 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	append modules_table_html "
	<li>$module_pretty_name
	(<a href=\"group-type-module-remove.tcl?[export_url_vars group_type module_key]\">remove</a>)
	"

	incr module_counter
    }
    
    if { $module_counter == 0 } {
	append modules_table_html "
	no modules are associated with this group type</tr>
	"
    }

    append modules_html "
    
    $modules_table_html
    
    "
    if { $module_available_p } {
	append modules_html "
	<p>
	<li><a href=\"group-type-module-add.tcl?[export_url_vars group_type]\">add module</a>
	"
    }
} else {
    append modules_html "
    Groups of this type are granted complete module administration. Modules can be associated with the groups only on the group level.
    "
}

ns_write "
<h3>Modules associated with groups in $group_type_pretty_name</h3>
<ul>
$modules_html
</ul>
"

append data_html "
<table border=0 width=80%>
"
set number_of_fields [database_to_tcl_string $db "select count(*) from user_group_type_fields where group_type = '$QQgroup_type'"]

set selection [ns_db select $db "select * from user_group_type_fields where group_type = '$QQgroup_type'
order by sort_key"]

set counter 0 
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter 

    if { $counter == $number_of_fields } {
	append data_html "<tr><td>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"field-add.tcl?group_type=[ns_urlencode $group_type]&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"field-delete.tcl?[export_url_vars group_type column_name group_type_pretty_name]\">delete</a>&nbsp;\]</font>\n"
    } else {
	append data_html "<tr><td>$column_name ($pretty_name), $column_actual_type ($column_type) $column_extra<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"field-add.tcl?group_type=[ns_urlencode $group_type]&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"field-swap.tcl?group_type=[ns_urlencode $group_type]&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;|&nbsp;<a href=\"field-delete.tcl?[export_url_vars group_type column_name group_type_pretty_name]\">delete</a>&nbsp;\]</font>\n"
    }
}

if { $counter == 0 } {
    append data_html "
    <tr><td>no group-specific data currently collected
    "
}

append data_html "
</table>
<p>
<li><a href=\"field-add.tcl?[export_url_vars group_type]\">add a field</a>
"

ns_write "
<h3>Data that we collect for this type of group</h3>
<ul>
$data_html
</ul>
"

append user_data_html "
<table border=0 width=80%>
"

set number_of_fields [database_to_tcl_string $db "select count(*) from user_group_type_member_fields where group_type = '$QQgroup_type'"]

set selection [ns_db select $db "select field_name, field_type, sort_key
from user_group_type_member_fields
where group_type = '$QQgroup_type'
order by sort_key"]

set counter 0

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    incr counter

    if { $counter == $number_of_fields } {
	append user_data_html "<tr><td>$field_name ($field_type)<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"group-type-member-field-add.tcl?group_type=[ns_urlencode $group_type]&after=$sort_key\">insert&nbsp;after</a>&nbsp;\]&nbsp;|&nbsp;<a href=\"group-type-member-field-delete.tcl?[export_url_vars group_type field_name group_type_pretty_name]\">delete</a>&nbsp;\]</font>\n"
    } else {
	append user_data_html "<tr><td>$field_name ($field_type)<td><font size=-1 face=\"arial\">\[&nbsp;<a href=\"group-type-member-field-add.tcl?group_type=[ns_urlencode $group_type]&after=$sort_key\">insert&nbsp;after</a>&nbsp;|&nbsp;<a href=\"group-type-member-field-swap.tcl?group_type=[ns_urlencode $group_type]&sort_key=$sort_key\">swap&nbsp;with&nbsp;next</a>&nbsp;\]&nbsp;|&nbsp;<a href=\"group-type-member-field-delete.tcl?[export_url_vars group_type field_name group_type_pretty_name]\">delete</a>&nbsp;\]</font>\n"
    }
}

if { $counter == 0 } {
    append user_data_html "
    <tr><td>No group-type-specific member data currently collected.
    "
}

append user_data_html "
</table>
<p>
<li><a href=\"group-type-member-field-add.tcl?[export_url_vars group_type]\">add a field</a>
"

ns_write "
<h3>Data that we collect for each user of this type of group</h3>
<ul>
$user_data_html
</ul>
"

append extreme_html "
<form method=GET action=\"group-type-delete.tcl\">
[export_form_vars group_type]
<input type=submit value=\"Delete This Group Type\">
</form>
"
ns_write "
<h3>Extreme Actions</h3>
<ul>
$extreme_html
</ul>

[ad_admin_footer]
"
