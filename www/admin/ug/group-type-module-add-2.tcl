# $Id: group-type-module-add-2.tcl,v 3.0.4.1 2000/04/28 15:09:33 carsten Exp $
# File:     /admin/ug/group-type-module-add-2.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  associates module with the group type

set_the_usual_form_variables
# group_type_module_id, group_type, module_key
# maybe return_url

if { ![info exists return_url] } {
    set return_url "group-type.tcl?group_type=[ns_urlencode $group_type]"
}

set exception_text ""
set exception_count 0

set db_conns [ns_db gethandle [philg_server_default_pool] 2]
set db [lindex $db_conns 0]
set db_sub [lindex $db_conns 1]

if [catch { 
    ns_db dml $db "begin transaction"

    ns_db dml $db "
    insert into user_group_type_modules_map
    (group_type_module_id, group_type, module_key)
    values 
    ($group_type_module_id, '$QQgroup_type', '$QQmodule_key')
    "

    set selection [ns_db 1row $db "
    select pretty_name as module_pretty_name, section_type_from_module_key(module_key) as section_type
    from acs_modules where module_key='$QQmodule_key'"]
    set_variables_after_query

    # select all the groups of this group type, which don't have this module already installed
    set selection [ns_db select $db "
    select content_sections.group_id as module_existing_group_id
    from content_sections, user_groups
    where content_sections.scope='group'
    and content_sections.group_id=user_groups.group_id
    and user_groups.group_type='$QQgroup_type'
    and module_key='$QQmodule_key' for update"]
    
    set existing_module_groups_counter 0
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	lappend existing_module_groups_list $module_existing_group_id
	incr existing_module_groups_counter
    }
    
    if { $existing_module_groups_counter > 0 } {
	set existing_modules_sql "and group_id not in ([join $existing_module_groups_list ", "])"
    } else {
	set existing_modules_sql ""
    }

    set selection [ns_db select $db "
    select group_id as insert_group_id, 
           uniq_group_module_section_key('$QQmodule_key', group_id) as insert_section_key
    from user_groups
    where group_type='$QQgroup_type'
    $existing_modules_sql for update"]

    set insertion_sql_list [list]
    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	lappend insertion_sql_list "
	insert into content_sections
	(section_id, scope, section_type, requires_registration_p, visibility, group_id, 
	section_key, module_key, section_pretty_name, enabled_p)
	values
	(content_section_id_sequence.nextval, 'group', '[DoubleApos $section_type]', 'f', 'public', $insert_group_id, 
	'[DoubleApos $insert_section_key]', '$QQmodule_key', '[DoubleApos $module_pretty_name]', 't')
	"
    }

    foreach insertion_sql $insertion_sql_list {
	ns_db dml $db $insertion_sql
    }

    
    ns_db dml $db "end transaction"
    
} errmsg] {
    # Oracle choked on the insert
    ns_db dml $db "abort transaction"
    
    # detect double click
    set selection [ns_db 0or1row $db "
    select 1
    from user_group_type_modules_map
    where group_type_module_id= $group_type_module_id"]
    
    if { ![empty_string_p $selection] } {
	# it's a double click, so just redirect the user to the index page
	ad_returnredirect $return_url
	return
    }
    
    ns_log Error "[info script] choked. Oracle returned error:  $errmsg"
    
    ad_return_error "Error in insert" "
    We were unable to do your insert in the database. 
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

ad_returnredirect $return_url







