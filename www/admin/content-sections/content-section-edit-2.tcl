# /www/admin/content-sections/content-section-edit-2.tcl
ad_page_contract {
    Editing a content section

    Scope aware. scope := (public|group). Scope related variables are passed implicitly in 
    the local environment and checked with ad_scope_error_check.

    @author  tarik@arsdigita.com
    @creation-date   22/12/99
    @cvs-id content-section-edit-2.tcl,v 3.2.2.7 2000/07/27 19:43:24 lutter Exp

    @param section_key
    @param new_section_key
    @param section_pretty_name
    @param section_type
    @param section_url_stub
    @param module_key
    @param sort_key
    @param intro_blurb
    @param help_blurb
    @param visibility
    @param requires_registration_p

} {
    section_key:notnull
    new_section_key:optional
    section_pretty_name:notnull
    section_type:optional
    section_url_stub:optional
    module_key:optional
    sort_key:notnull,integer
    intro_blurb
    help_blurb
    {visibility public}
    {requires_registration_p f}
}

ad_scope_error_check
ad_scope_authorize $scope admin group_admin none

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

if { $section_type=="static" } {
    set url_stub_sql "section_url_stub = :section_url_stub,"
} else {
    set url_stub_sql ""
}


# So the input is good --
# Now we'll do the update of the content_sections table.

if { [catch {
    db_dml content_update_section "update content_sections 
 set section_key = :new_section_key, 
 section_pretty_name = :section_pretty_name, 
 $url_stub_sql 
 sort_key = :sort_key, 
 requires_registration_p = :requires_registration_p, 
 visibility = :visibility, 
 intro_blurb = :intro_blurb, 
 help_blurb = :help_blurb 
 where [ad_scope_sql] 
 and section_key = :section_key 
" 
} errmsg] } {
    # Oracle choked on the update
    
    if { [string compare $section_key $new_section_key] != 0 } {
	set section_pretty_name [db_string content_select_pretty_name "
	select section_pretty_name 
	from content_sections 
	where [ad_scope_sql] and section_key = :new_section_key" -default ""]
	db_release_unused_handles
	
	if { ![empty_string_p $section_pretty_name] } {
	    # user supplied name, which violates section_key unique constraint
	    incr exception_count
	    append exception_text "<li>Section key $new_section_key is already used by section <i>$section_pretty_name</i>.
	    Please go back and choose different section key."
	    ad_scope_return_complaint $exception_count $exception_text
	    return
	}
    }
    
    db_release_unused_handles
    ad_scope_return_error "Error in update" "
    We were unable to do your update in the database. Here is the error that was returned:
    <p>
    <blockquote>
    <pre>
    $errmsg
    </pre>
    </blockquote>"
    return
}

ad_returnredirect index

