# $Id: content-section-add-2.tcl,v 3.0.4.1 2000/04/28 15:08:29 carsten Exp $
# File:     /admin/content-sections/content-section-add-2.tcl
# Date:     22/12/99
# Contact:  tarik@arsdigita.com
# Purpose:  adding a content section
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)
# section_id, section_key, section_type, section_pretty_name, section_url_stub, sort_key, requires_registration_p, intro_blurb, help_blurb
# maybe section_type (section_type is provided for static and custom sections only, for system and admin sections we have to figure out
# the section_type using module_key and quering acs_modules table)
# maybe module_key (if section is system or admin section we expect the module_key)

ad_scope_error_check

set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

# let's figure out the section_type using module_key for system and admin sections
if { [info exists module_key] } {
    set section_type [database_to_tcl_string $db "select module_type from acs_modules where module_key='[DoubleApos $module_key]'"]
}

set exception_count 0
set exception_text ""

# we were directed to return an error for section_key
if {![info exists section_key] || [empty_string_p $section_key]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for section_key.<br>"
} 

# we were directed to return an error for section_pretty_name
if {![info exists section_pretty_name] || [empty_string_p $section_pretty_name]} {
    incr exception_count
    append exception_text "<li>You did not enter a value for section_pretty_name.<br>"
} 

# we were directed to return an error for empty section_url_stub when section_type=static
if { ([string compare $section_type static]==0) && (![info exists section_url_stub] || [empty_string_p $section_url_stub])} {
    incr exception_count
    append exception_text "<li>You did not enter a value for section_url_stub.
                               Section URL stub must be specifed for the static sections.<br>"
} 

# if registration_enabled_p and visibility are not provided (in the case of module, then set them to default values)
if { ![info exists requires_registration_p] || [empty_string_p $requires_registration_p]} {
    set requires_registration_p f
    set QQrequires_registration_p f
} 

if { ![info exists visibility] || [empty_string_p $visibility] } {
    set visibility public
    set QQvisibility public
} 

if {[string length $intro_blurb] > 4000} {
    incr exception_count
    append exception_text "<LI>\"intro_blurb\" is too long\n"
}

if {[string length $help_blurb] > 4000} {
    incr exception_count
    append exception_text "<LI>\"help_blurb\" is too long\n"
}

if {$exception_count > 0} {
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

# So the input is good --
# Now we'll do the insertion in the content_sections table.


if { $section_type=="admin" || $section_type=="system" } {
    set type_cols "section_type, module_key"
    set type_vals "'[DoubleApos $section_type]', '[DoubleApos $module_key]'"
} 

if { $section_type=="custom" } {
    set type_cols "section_type"
    set type_vals "'[DoubleApos $section_type]'"
}

if { $section_type=="static" } {
    set type_cols "section_type, section_url_stub"
    set type_vals "'[DoubleApos $section_type]', '$QQsection_url_stub'"
}

if [catch {
    ns_db dml $db "
    insert into content_sections
    (section_id, section_key, section_pretty_name, [ad_scope_cols_sql], $type_cols,
    sort_key, requires_registration_p, visibility, intro_blurb, help_blurb)
    values
    ($section_id, '$QQsection_key', '$QQsection_pretty_name', [ad_scope_vals_sql], $type_vals,
    '$QQsort_key', '$QQrequires_registration_p', '$QQvisibility', '$QQintro_blurb', '$QQhelp_blurb')" 
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
	ad_returnredirect index.tcl?[export_url_scope_vars]
	return
    }

    set selection [ns_db 0or1row $db "
    select section_pretty_name
    from content_sections 
    where [ad_scope_sql] and section_key='[DoubleApos $section_key]'"]

    if { ![empty_string_p $selection] } {
	# user supplied name, which violates section_key unique constraint
	set_variables_after_query
	incr exception_count
	append exception_text "<li>Section key $section_key is already used by section $section_pretty_name.
 	                       Please go back and choose different section key."
	ad_scope_return_complaint $exception_count $exception_text $db
	return
    }

    ad_scope_return_error "Error in insert" "We were unable to do your insert in the database. 
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>" $db
    return
}

ad_returnredirect "index.tcl?[export_url_scope_vars]"









