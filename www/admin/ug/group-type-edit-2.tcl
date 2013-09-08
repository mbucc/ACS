ad_page_contract {
    @param group_type  group_type, plus all the other group type variables from the form
    @param group_type_module_id (necessary for insertion of content-sections module  into content_sections table in the case group_module_administration is enabling or full)
    @param pretty_name The name of the group type
    @param pretty_plural The plural name of more than one group type
    @param approval_policy The approval policy for how a new group of this group type can be created
    @param default_new_member_policy The default policy for how a group will handle new members
    @param group_module_administration The policy for how a group can administer its module associations

    @cvs-id group-type-edit-2.tcl,v 3.1.6.4 2000/07/21 03:58:16 ron Exp
} {
    group_type:notnull
    group_type_module_id:notnull,naturalnum
    pretty_name:notnull
    pretty_plural:notnull
    approval_policy:notnull
    default_new_member_policy:notnull
    group_module_administration:notnull
}

set update_statement "
    update user_group_types
    set pretty_name = :pretty_name,
        pretty_plural = :pretty_plural,
        approval_policy = :approval_policy,
        default_new_member_policy = :default_new_member_policy,
        group_module_administration = :group_module_administration
    where group_type = :group_type
"

set return_url "group-type?[export_url_vars group_type]"

if [catch { 
    db_transaction {
    
    # this updates the user_group_types table per data entered in the form
    db_dml group_type_update $update_statement
    
    if { $group_module_administration=="full" } {
	# we are giving full module administration to the groups
	# in this case we shouldn't have any group_type to module mappings,
	# so that we can guarantee constistency in module mappings in the case
	# module administration is switched to enabling or none
	db_dml group_type_mm_delete "
	delete from user_group_type_modules_map where group_type=:group_type"
    }
    
    if { $group_module_administration=="full" ||  $group_module_administration=="enabling" } {
	# if group_module_administration is full or enabling we want to make sure that content-sections
	# module is installed (otherwise, group_module_administration doesn't make sense)
	
	set module_key "content-sections"
	
	
	db_dml insert_gt_mod_map "
	insert into user_group_type_modules_map
	(group_type_module_id, group_type, module_key)
	select :group_type_module_id, :group_type, :module_key
	from dual where not exists (select 1 from user_group_type_modules_map 
                                    where group_type=:group_type and module_key=:module_key)
	"
	
	db_1row get_prettyname "
	select pretty_name as module_pretty_name, section_type_from_module_key(module_key) as section_type
	from acs_modules where module_key=:module_key"
	
	
	# select all the groups of this group type, which don't have this module already installed
	set existing_module_groups_counter 0

	db_foreach get_content_section_stuff "
	select content_sections.group_id as module_existing_group_id
	from content_sections, user_groups
	where content_sections.scope='group'
	and content_sections.group_id=user_groups.group_id
	and user_groups.group_type=:group_type
	and module_key=:module_key for update" {
	
	
	
	  
	    
	    lappend existing_module_groups_list $module_existing_group_id
	    incr existing_module_groups_counter
	}
	
	if { $existing_module_groups_counter > 0 } {
	    set existing_modules_sql "and group_id not in ([join $existing_module_groups_list ", "])"
	} else {
	    set existing_modules_sql ""
	}
	set insertion_sql_list [list]
	db_foreach get_group_ids_for_insert "
	select group_id as insert_group_id, 
	uniq_group_module_section_key(:module_key, group_id) as insert_section_key
	from user_groups
	where group_type=:group_type
	$existing_modules_sql for update" {

	
	
	    lappend insertion_sql_list "
	    insert into content_sections
	    (section_id, scope, section_type, requires_registration_p, visibility, group_id, 
	    section_key, module_key, section_pretty_name, enabled_p)
	    values
	    (content_section_id_sequence.nextval, 'group', :section_type, 'f', 'public', :insert_group_id, 
	    :insert_section_key, :module_key, :module_pretty_name, 't')
	    "
	}
	
	foreach insertion_sql $insertion_sql_list {
	    db_dml insert_into_cs_sql_list $insertion_sql
	}
    } 
    
    }
} errmsg] {
    # Oracle choked on the insert
    db_dml abort_transaction "abort transaction"
    
    # detect double click
    if { [db_0or1row get_dclick_ugtmm "
    select 1
    from user_group_type_modules_map
    where group_type_module_id= :group_type_module_id"] == 0 } {
    

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

    




