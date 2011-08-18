# $Id: group-module-add-2.tcl,v 3.0.4.1 2000/04/28 15:09:28 carsten Exp $
# File:     /admin/ug/group-module-add-2.tcl
# Date:     12/31/99
# Contact:  tarik@arsdigita.com
# Purpose:  adding a module to the group

set_the_usual_form_variables
# module_key, group_id, section_id

set db [ns_db gethandle]

set return_url "group.tcl?[export_url_vars group_id]"

if [catch {
    set section_key [database_to_tcl_string $db "
    select uniq_group_module_section_key('$QQmodule_key', $group_id) from dual"]
    
    ns_db dml $db "
    insert into content_sections
    (section_id, section_key, section_pretty_name, scope, group_id, section_type, module_key,
    requires_registration_p, visibility, enabled_p)
    select $section_id, '[DoubleApos $section_key]', pretty_name, 'group', $group_id, 
           section_type_from_module_key(module_key), module_key, 'f', 'public', 't'
    from acs_modules where module_key='$QQmodule_key'
    "
} errmsg] {
    # Oracle choked on the insert
    
    # detect double click
    set selection [ns_db 0or1row $db "
    select section_id 
    from content_sections 
    where section_id=$section_id"]
    
    if { ![empty_string_p $selection] } {
	# it's a double click, so just redirct the user to the index page
	set_variables_after_query
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








