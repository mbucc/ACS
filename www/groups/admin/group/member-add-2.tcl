# $Id: member-add-2.tcl,v 3.0 2000/02/06 03:45:53 ron Exp $
# File:     /groups/admin/group/member-add-2.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  add a member to the user group
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables
# user_id_from_search, maybe role 

set db [ns_db gethandle]

if ![info exists role] {
    set role ""
}
    
if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

set name [database_to_tcl_string $db "select first_names || ' ' || last_name from users where user_id = $user_id_from_search"]
set selection [ns_db 1row $db "select group_name, group_type, multi_role_p from user_groups where group_id = $group_id"]
set_variables_after_query

ReturnHeaders 

set group_admin_url [ns_set get $group_vars_set group_admin_url]

ns_write "
[ad_scope_admin_header "Add $name" $db]
[ad_scope_admin_page_title "Add $name" $db]
[ad_scope_admin_context_bar "Add $name"]
<hr>
"

append html "
<form method=get action=\"member-add-3.tcl\">
[export_form_vars group_id user_id_from_search]
"

if { ![empty_string_p $role] } {
    append html "[export_form_vars role]"
} else {

    if { [string compare $multi_role_p "t"] == 0 } {
	# all groups must have an adminstrator role
	set existing_roles [database_to_tcl_list $db "select role from user_group_roles where group_id = $group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if { [llength $existing_roles] > 0 } {
	    append html "
	    <select name=existing_role>
	    [ad_generic_optionlist $existing_roles $existing_roles $role]
	    </select>
	    "
	}
	append html "</tr>"
    } else {
	set existing_roles [database_to_tcl_list $db "select distinct role from user_group_map where group_id = $group_id"]
	if {[lsearch $existing_roles "administrator"] == -1 } {
	    lappend existing_roles "administrator"
	}
	if {[lsearch $existing_roles "all"] == -1 } {
	    lappend existing_roles "all"
	}
	if { [llength $existing_roles] > 0 } {
	    append html "
	    <select name=existing_role>
	    <option value=\"\">choose an existing role
	    <option>[join $existing_roles "\n<option>"]
	    </select>
	    "
	}
	append html "
	<p>
	Define a new role for this group:
	<input type=text name=new_role size=30>
	"
    }
}

append html "
<p>

<center>
<input type=submit value=\"Confirm\">
</center>
</form>
"

ns_write "
$html
[ad_scope_admin_footer]
"

