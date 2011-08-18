# $Id: index.tcl,v 3.1.2.2 2000/04/19 11:13:28 carsten Exp $
# File: /groups/group/index.tcl
# Date: mid-1998
# Contact: teadams@arsdigita.com, tarik@arsdigita.com
# Purpose: this is the group public page
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set user_id [ad_get_user_id]

set group_name [ns_set get $group_vars_set group_name]
set group_public_url [ns_set get $group_vars_set group_public_url]
set group_admin_url [ns_set get $group_vars_set group_admin_url]

set db [ns_db gethandle]

set selection [ns_db 1row $db "
select ug.approved_p, ug.creation_user, ug.registration_date,  ug.group_type, 
       ug.new_member_policy, u.first_names, u.last_name
from user_groups ug, users u
where group_id = $group_id
and ug.creation_user = u.user_id"]
set_variables_after_query

ReturnHeaders 

if { $approved_p == "f" } {
    ns_write "
    [ad_scope_header "Main Page" $db]
    [ad_scope_page_title "Main Page" $db]
    [ad_scope_context_bar_ws_or_index $group_name] 
    <hr>
    <blockquote>
    <font color=red>this group is awaiting approval by [ad_system_owner]</font>
    </blockquote>
    [ad_scope_footer]
    "
    return
}

append page_top "
[ad_scope_header "Main Page" $db]
[ad_scope_page_title "Main Page" $db]
[ad_scope_context_bar_ws_or_index $group_name] 
<hr>
"

if { [ad_user_group_authorized_admin $user_id $group_id $db] && ![empty_string_p $group_admin_url] } {
    append page_top [help_upper_right_menu [list "$group_admin_url/" "Administration Page"]]
}

ns_write $page_top

# get group sections 
set selection [ns_db select $db "
select section_key, section_pretty_name, section_type
from content_sections 
where scope='group' 
and group_id=$group_id
and (section_type='static' or
     section_type='custom' or
     (section_type='system' and module_key!='custom-sections'))
and enabled_p='t'
order by sort_key
"]

set system_section_counter 0
set non_system_section_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { [string compare $section_type system]==0 } {
    
	append system_sections_html "
	<a href=[ad_urlencode $section_key]/>$section_pretty_name</a><br>
	"    
	incr system_section_counter
    } else {
	append non_system_sections_html "
	<a href=[ad_urlencode $section_key]/>$section_pretty_name</a><br>
	"    
	incr non_system_section_counter
    }

}

append system_sections_html "
<a href=\"spam-index.tcl\">Email</a><br>
"
incr system_section_counter

set html ""
if { [expr $system_section_counter + $non_system_section_counter]>0 } {
    append html "
    <h4>Sections</h4>
    "
    
    if { $system_section_counter>0 } {
	append html "
	$system_sections_html
	"
    }

    if { $non_system_section_counter>0 } {
	append html "
	<br>
	$non_system_sections_html
	"
    }

}

# let's look for administrators

set selection [ns_db select $db "select user_id as admin_user_id, first_names || ' ' || last_name as name
from users 
where ad_user_has_role_p ( user_id, $group_id, 'administrator' ) = 't'"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    append administrator_items "<a href=\"/shared/community-member.tcl?user_id=$admin_user_id\">$name</a><br>\n"
}

if [info exists administrator_items] {
    append html "<h4>Group Administrators</h4>\n\n$administrator_items\n"
}

if { $user_id == 0 } {
    if { $new_member_policy != "closed" } {
	# there is at least some possibility of a member joining
	append html "If you want to join this group, you'll need to <a href=\"/register.tcl?return_url=[ad_urlencode "$group_public_url/member-add.tcl"]\">log in </a>."
    }
} else {
    # the user is logged in
    if { [string compare [database_to_tcl_string $db "select ad_group_member_p ( $user_id, $group_id ) from dual"] "t"] == 0 } {
	# user is already a member
	append html "<br>You are a member of this group.  You can <a href=\"member-remove.tcl\">remove yourself</a>."
    } else {
	switch $new_member_policy {
	    "open"  { 
		append html "<h4>Join</h4>
		This group has an open enrollment policy.  You can simply
		<a href=\"member-add.tcl\">sign up</a>."
	    }
	    "wait"  {
		append html "<h4>Join</h4>
		The administrator approves users who wish to end this group.
		<a href=\"member-add.tcl\">Submit your name for approval</a>."
	    }
	    "closed" {
		append html "
		This group has closed membership policy. You cannot become a member of this group."
	    }
	} 
    }
}

ns_write "
<blockquote>
$html
</blockquote>
[ad_style_bodynote "Created by <a href=\"/shared/community-member.tcl?user_id=$creation_user\">$first_names $last_name</a> on [util_AnsiDatetoPrettyDate $registration_date]"]
[ad_scope_footer]
"











