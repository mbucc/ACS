# /www/pvt/content-help.tcl
ad_page_contract {
    Return help about a content section.

    @author
    @creation-date
    @cvs-id content-help.tcl,v 3.0.14.4 2000/09/22 01:39:10 kevin Exp
} {
    section_id:notnull,integer
}

set user_id [ad_verify_and_get_user_id]

if {![db_0or1row content_help {
    select section_pretty_name, help_blurb
    from content_sections
    where section_id = :section_id
} -bind [ad_tcl_vars_to_ns_set section_id]]} {
    ad_return_error "Help not found" "Unable to find help on that section."
    return 
}



doc_return  200 "text/html" "
[ad_header "$section_pretty_name help"]
[ad_decorate_top "<h2>$section_pretty_name help</h2>
[ad_context_bar_ws "Help"]
" [ad_parameter WorkspacePageDecoration pvt]]

<hr>

$help_blurb

[ad_footer]
"
