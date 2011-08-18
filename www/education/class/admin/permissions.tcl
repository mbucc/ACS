#
# /www/education/class/admin/permissions.tcl
#
# this page is the index page for the class administrators
# 
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#

set db [ns_db gethandle]

# gets the class_id.  If the user is not an admin of the class, it
# displays the appropriate error message and returns so that this code
# does not have to check the class_id to make sure it is valid

set id_list [edu_group_security_check $db edu_class "Edit Permissions"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]
set class_name [lindex $id_list 2]


set html_to_return "
[ad_header "$class_name Administration @ [ad_system_name]"]

<h2>$class_name Administration</h2>

[ad_context_bar_ws_or_index [list "../one.tcl" "$class_name Home"] [list "" "Administration"] "Class Permissions"]

<hr>
<blockquote>
"


append permissions_html "
<h3>Permissions</h3>
<ul>
<li> <b> Manage Users </b> - Add or delete users from the class; change the role of a user within the class; add people to teams or sections.

<li> <b> Add Tasks </b> - Add assignments, projects, or exams to the web page.
<li> <b> Edit Tasks </b> - Edit the attributes of existing assignments, projects, or exams.
<li> <b> Delete Tasks </b> - Delete assignments, projects, or exams.
<li> <b> Edit Class Properties </b> - Edit the properties of the class such as description, scheduled meeting times, or title.
<li> <b> Manage Communications </b> - Create Bulletin Boards and Chat rooms; post news messages.
<li> <b> Edit Permissions </b> - View/change the contents of this page.
<li> <b> Evaluate </b> - Assign grades/perform reviews on students.
<li> <b> Spam Users </b> - Send email to groups of users within the class.  Users with this permission can also see all of the spam history for the class.  It is recommended that you only give this permission to TAs and Professors.
<li> <b> Submit Tasks </b> - upload answers to a task from the user pages.
<li> <b> View Admin Pages </b> - View anything within the class/admin/ directory; without permission for this, the role will not be able to perform any of the above actions.
</ul>
<p>"

set actions_list [database_to_tcl_list $db "select action from user_group_actions where group_id = $class_id"]

set roles_list [database_to_tcl_list_list $db "select roles.role, 
         map.pretty_role,
         sort_key
    from user_group_roles roles, 
         edu_role_pretty_role_map map 
   where roles.group_id = $class_id 
     and lower(roles.role) = lower(map.role) 
     and roles.group_id = map.group_id 
order by sort_key"]

set role_swap_table "<table>"
set action_table_title "<table border=1 cellpadding=2><tr><th>Action \\\\ Role</th>"

set count 0
set list_length [llength $roles_list]

foreach role $roles_list {
    append action_table_title "<th>[lindex $role 1]</th>"
    append role_swap_table "<tr><td>[lindex $role 1]</td><td>"
    if {$count < [expr $list_length - 1]} {
	append role_swap_table "<a href=\"key-swap.tcl?key=[lindex $role 2]&column=sort_key\">swap with next</a>"
    } else {
	append role_swap_table "[ad_space]"
    }
    incr count
    append role_swap_table "</td></tr>"
}

append action_table_title "</tr>"
append role_swap_table "</table>"



append action_table "<tr>"

set roles_with_mapping ""
set group_id $class_id

foreach action $actions_list {
    append action_table "<tr><th align=left>$action</th>\n"
    
    set allowed_roles_for_action [database_to_tcl_list $db "select role from user_group_action_role_map where group_id = $class_id and lower(action) = lower('[DoubleApos $action]')"]

    foreach role_item $roles_list {
	set role [lindex $role_item 0]
	
	if {[lsearch $allowed_roles_for_action $role] == -1} {
	    append action_table "
	    <td align=center>
	    <a href=\"action-role-map.tcl?[export_url_vars action role group_id]\">
	    Denied</a></td>\n"
	} else {
	    lappend actions_with_mapping $action
	    append action_table "
	    <td align=center>
	    <a href=\"action-role-unmap.tcl?[export_url_vars action role group_id]\">
	    Allowed</a></td>\n"
	}
    }

    append action_table "</tr>"
}





append action_table "</table>"

append permissions_html "
$action_table_title
$action_table
"


set role_swap_text "
<p>[ad_space]<p>
<h3>Role Display Order</h3>
<ul>
You may use this to alter the order roles
are displayed on various pages throughout the system.
<p>
$role_swap_table
</ul>
"


set file_permissions_hierarchy "
<p>[ad_space]<p>
<h3>File Permission Hierarchy</h3>
<ul>
This determines the order permissions are displayed when uploading a
file.  For instance, if 'Professor' is the first on in the list, then
someone with the role of 'Professor' will have all permissions on all
files uploaded.
<p>
<table>
"

set roles_list [database_to_tcl_list_list $db "select roles.role, 
         map.pretty_role,
         priority
    from user_group_roles roles, 
         edu_role_pretty_role_map map 
   where roles.group_id = $class_id 
     and lower(roles.role) = lower(map.role) 
     and roles.group_id = map.group_id 
order by priority"]

set count 0
set list_length [llength $roles_list]

foreach role $roles_list {
    append file_permissions_hierarchy "<tr><td>[lindex $role 1]</td><td>"
    if {$count < [expr $list_length - 1]} {
	append file_permissions_hierarchy "<a href=\"key-swap.tcl?key=[lindex $role 2]&column=priority\">swap with next</a>"
    } else {
	append file_permissions_hierarchy "[ad_space]"
    }
    incr count
    append file_permissions_hierarchy "</td></tr>"
}

append file_permissions_hierarchy "</table></ul>"


ns_db releasehandle $db

ns_return 200 text/html "
$html_to_return
$permissions_html
$file_permissions_hierarchy
$role_swap_text
</blockquote>
[ad_footer]
"




