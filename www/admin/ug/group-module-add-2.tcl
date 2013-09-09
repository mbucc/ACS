#/admin/ug/group-module-add-2.tcl

ad_page_contract {
    Purpose:  adding a module to the group    
    @param module_key the module key ID
    @param group_id the ID of the group
    @param section_id the ID of the desired section

    @creation-date 31 December 1999
    @author tarik@arsdigita.com
    @cvs-id group-module-add-2.tcl,v 3.2.2.5 2000/07/22 06:12:35 ryanlee Exp
}  {
    module_key:notnull
    group_id:notnull,naturalnum
    section_id:notnull,naturalnum
}

set return_url "group?[export_url_vars group_id]"

if [catch {
    set section_key [db_string get_section_get "
    select uniq_group_module_section_key(:module_key, :group_id) from dual"]
    
    db_dml content_section_add_key "
    insert into content_sections
    (section_id, section_key, section_pretty_name, scope, group_id, section_type, module_key,
    requires_registration_p, visibility, enabled_p)
    select :section_id, :section_key, pretty_name, 'group', :group_id, 
           section_type_from_module_key(module_key), module_key, 'f', 'public', 't'
    from acs_modules where module_key=:module_key
    "
} errmsg] {
    # Oracle choked on the insert
    
    # detect double click
    if { [db_0or1row get_section_id "
    select section_id 
    from content_sections 
    where section_id=:section_id"] ==0 } {
   
	# it's a double click, so just redirct the user to the index page

	ad_returnredirect $return_url
	return
    }

    ad_return_error "Error in insert" "We were unable to do your insert in the database. 
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




