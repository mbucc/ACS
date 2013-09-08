# /www/admin/content-sections/content-section-add-2.tcl
ad_page_contract {
    Adds a content section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author Contact:  tarik@arsdigita.com
    @creation-date 22/12/99
    @cvs-id content-section-add-2.tcl,v 3.2.2.9 2001/01/10 17:16:42 khy Exp

    @param section_id
    @param sort_key
    @param section_key
    @param section_type
    @param module_key
    @param section_pretty_name
    @param section_url_stub
    @param requires_registration_p
    @param visibility
    @param intro_blurb
    @param help_blurb
} {
    section_id:notnull,integer,verify
    sort_key:notnull,integer
    section_key:notnull
    section_type:optional
    module_key:optional
    section_pretty_name:notnull
    section_url_stub:optional
    {requires_registration_p f}
    {visibility public}
    intro_blurb
    help_blurb
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

# let's figure out the section_type using module_key for system and admin sections
if { [info exists module_key] } {
    set section_type [db_string content_get_module_key "select module_type from acs_modules where module_key = :module_key"]
}

set exception_count 0
set exception_text ""

# we were directed to return an error for empty section_url_stub when section_type=static
if { ([string compare $section_type static]==0) && (![info exists section_url_stub] || [empty_string_p $section_url_stub])} {
    incr exception_count
    append exception_text "<li>You did not enter a value for section_url_stub.
                               Section URL stub must be specifed for the static sections.<br>"
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
    ad_scope_return_complaint $exception_count $exception_text
    return
}

# So the input is good --
# Now we'll do the insertion in the content_sections table.

if { $section_type=="admin" || $section_type=="system" } {
    set type_cols "section_type, module_key"
    set type_vals ":section_type, :module_key"
} 

if { $section_type=="custom" } {
    set type_cols "section_type"
    set type_vals ":section_type"
}

if { $section_type=="static" } {
    set type_cols "section_type, section_url_stub"
    set type_vals ":section_type, :section_url_stub"
}

if [catch {
    db_dml content_insert_section "
    insert into content_sections 
 (section_id, section_key, section_pretty_name, [ad_scope_cols_sql], $type_cols, 
 sort_key, requires_registration_p, visibility, intro_blurb, help_blurb) 
 values 
 (:section_id, :section_key, :section_pretty_name, [ad_scope_vals_sql], $type_vals, 
 :sort_key, :requires_registration_p, :visibility, :intro_blurb, :help_blurb)" 
} errmsg] {
    # Oracle choked on the insert
    
    # detect double click
    set result_count [db_0or1row content_count_section_id "
    select section_id 
 from content_sections 
 where section_id = :section_id"]
    if { $result_count } {
	# it's a double click, so just redirct the user to the index page
	ad_returnredirect index
	return
    }

    db_0or1row content_select_pretty_name "
    select section_pretty_name 
 from content_sections 
 where [ad_scope_sql] and section_key = :section_key"

    if { ![empty_string_p $section_pretty_name] } {
	# user supplied name, which violates section_key unique constraint
	incr exception_count
	append exception_text "<li>Section key $section_key is already used by section $section_pretty_name.
 	                       Please go back and choose different section key."
	db_release_unused_handles
	ad_scope_return_complaint $exception_count $exception_text
	return
    }

    db_release_unused_handles
    ad_scope_return_error "Error in insert" "We were unable to do your insert in the database. 
    Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

ad_returnredirect "index"


