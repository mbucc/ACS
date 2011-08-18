# $Id: index.tcl,v 3.0 2000/02/06 03:45:52 ron Exp $
# File:     /groups/admin/group/index.tcl
# Date:     mid-1998
# Contact:  teadams@mit.edu, tarik@arsdigita.com
# Purpose:  group administration main page
#
# Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
#       group_vars_set contains group related variables (group_id, group_name, group_short_name,
#       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
#       group_type_url_p, group_context_bar_list and group_navbar_list)

set group_admin_url [ns_set get $group_vars_set group_admin_url]
set group_public_url [ns_set get $group_vars_set group_public_url]

set db [ns_db gethandle]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id $db] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}


set selection [ns_db 1row $db "
select ug.approved_p, ug.creation_user, ug.registration_date, 
       ug.new_member_policy, ug.email_alert_p, ug.group_type, 
       ug.multi_role_p, ug.group_admin_permissions_p, ug.group_name,
       first_names, last_name
from user_groups ug, users u
where ug.group_id = $group_id
and ug.creation_user = u.user_id"]
set_variables_after_query

ReturnHeaders 

ns_write "
[ad_scope_admin_header $group_name $db]
[ad_scope_admin_page_title Administration $db]
[ad_scope_admin_context_bar $group_name]
<hr>
[help_upper_right_menu [list "$group_public_url/" "Public Page"]]
"

if { $approved_p == "f" } {
    ns_write "
    <blockquote>
    <font color=red>this group is awaiting approval</font>
    </blockquote>
    [ad_scope_admin_footer]
    "
    return
}

set info_table_name [ad_user_group_helper_table_name $group_type] 
set selection [ns_db 0or1row $db "select * from $info_table_name where group_id = $group_id"]

if { ![empty_string_p $selection] } {
    set set_variables_after_query_i 0
    set set_variables_after_query_limit [ns_set size $selection]
    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
	append html "<li>[ns_set key $selection $set_variables_after_query_i]: [ns_set value $selection $set_variables_after_query_i]\n"
	incr set_variables_after_query_i
    }
}

append html "
<h4>Group Administration</h4>
<a href=members.tcl>Membership</a><br>
<a href=spam-index.tcl>Group Spam</a><br>
"

set selection [ns_db select $db "
select section_id,section_key, section_pretty_name, section_type, module_key
from content_sections 
where scope='group' 
and group_id=$group_id
and (section_type!='static')
order by sort_key
"]

set return_url "$group_admin_url/"

set admin_section_counter 0
set system_section_counter 0
set custom_section_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query

    if { [string compare $section_type admin]==0 } {
    
	append admin_sections_html "
	<a href=[ad_urlencode $section_key]/index.tcl?[export_url_vars return_url]>$section_pretty_name</a><br>
	"    
    	incr admin_section_counter
    }
    
    if { [string compare $section_type system]==0 } {
    
	# custom sections module doesn't have any administration of it's own (handled inside content-sections module),
	# so we don't want to display link
	if { [string compare $module_key custom-sections]!=0 } {
	    append system_sections_html "
	    <a href=[ad_urlencode $section_key]/>$section_pretty_name</a><br>
	    "    
	    incr system_section_counter
	}
    }
    
    if { [string compare $section_type custom]==0 } {
    
	append custom_sections_html "
	<a href=custom-sections/index.tcl?[export_url_vars section_id]>$section_pretty_name</a><br>
	"  
	incr custom_section_counter
    }
}

if { $admin_section_counter>0 } {
    append html "
    $admin_sections_html
    <p>
    "
}

if { $system_section_counter>0 } {
    append html "
    <h4>Module Administration</h4>
    $system_sections_html
    <p>
    "
}

if { $custom_section_counter>0 } {
    append html "
    <h4>Custom Sections Administration</h4>
    $custom_sections_html
    <p>
    "
}

ns_write "
<blockquote>
$html
</blockquote>


[ad_scope_admin_footer]
"

