# /groups/admin/group/index.tcl

ad_page_contract {
    @cvs-id index.tcl,v 3.3.2.7 2000/09/22 01:38:10 kevin Exp
    @author  teadams@mit.edu, tarik@arsdigita.com

    Purpose:  group administration main page
    
    Note: group_id and group_vars_set are already set up in the environment by the ug_serve_section.
       group_vars_set contains group related variables (group_id, group_name, group_short_name,
       group_admin_email, group_public_url, group_admin_url, group_public_root_url, group_admin_root_url, 
       group_type_url_p, group_context_bar_list and group_navbar_list)
} { 
}

set group_admin_url [ns_set get $group_vars_set group_admin_url]
set group_public_url [ns_set get $group_vars_set group_public_url]

if { [ad_user_group_authorized_admin  [ad_verify_and_get_user_id]  $group_id] != 1 } {
    ad_return_error "Not Authorized" "You are not authorized to see this page"
    return
}

db_1row get_info_for_ug "
select ug.approved_p, ug.creation_user, ug.registration_date, 
       ug.new_member_policy, ug.email_alert_p, ug.group_type, 
       ug.multi_role_p, ug.group_admin_permissions_p, ug.group_name,
       first_names, last_name
from user_groups ug, users u
where ug.group_id = :group_id
and ug.creation_user = u.user_id"




set page_html "
[ad_scope_admin_header $group_name]
[ad_scope_admin_page_title Administration]
[ad_scope_admin_context_bar $group_name]
<hr>
[help_upper_right_menu [list "$group_public_url/" "Public Page"]]
"

if { $approved_p == "f" } {
    append page_html "
    <blockquote>
    <font color=red>this group is awaiting approval</font>
    </blockquote>
    [ad_scope_admin_footer]
    "
    return
}

set info_table_name [string toupper [ad_user_group_helper_table_name $group_type]]
set selection [ns_set create] 

if { [db_string user_group_info_table_exists {
    select count(*) from user_tables
    where table_name=:info_table_name
}] > 0 } {
    set supplemental_col_list [list]
    db_foreach group_columns "select column_name from user_group_type_fields where group_type = :group_type order by sort_key" {
	lappend supplemental_col_list $column_name
    }
    
    if { [llength $supplemental_col_list] > 0 && [db_0or1row select_supplemental_group_info "
        select [join $supplemental_col_list ", "]
        from $info_table_name
        where group_id = :group_id
    " -column_set selection] } {

        set set_variables_after_query_i 0
        set set_variables_after_query_limit [ns_set size $selection]
        while {$set_variables_after_query_i<$set_variables_after_query_limit} {
            append html "<li>[ns_set key $selection $set_variables_after_query_i]: [ns_set value $selection $set_variables_after_query_i]\n"
            incr set_variables_after_query_i
        }
    }
}

append html "
<h4>Group Administration</h4>
<a href=members>Membership</a><br>
<a href=spam-index>Group Spam</a><br>
"

set return_url "$group_admin_url/"

set admin_section_counter 0
set system_section_counter 0
set custom_section_counter 0

db_foreach get_section_info "
select section_id,section_key, section_pretty_name, section_type, module_key
from content_sections 
where scope='group' 
and group_id=:group_id
and (section_type!='static')
order by sort_key
" {



    if { [string compare $section_type admin]==0 } {
    
	append admin_sections_html "
	<a href=[ad_urlencode $section_key]/index?[export_url_vars return_url]>$section_pretty_name</a><br>
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
	<a href=custom-sections/index?[export_url_vars section_id]>$section_pretty_name</a><br>
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

append page_html "
<blockquote>
$html
</blockquote>

[ad_scope_admin_footer]
"



doc_return  200 text/html $page_html