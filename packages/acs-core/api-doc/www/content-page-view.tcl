ad_page_contract {
    Displays information about a content page.
    
    @param version_id the id of the package version the file belongs to
    @param path the path and filename of the page to document, relative to [acs_root_dir]
    
    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @creation-date 1 July 2000
    
    @cvs-id content-page-view.tcl,v 1.1.4.3 2000/07/21 03:55:39 ron Exp
} {
    version_id:optional
    path
}

if { [info exists version_id] } {
    api_set_public $version_id
} else {
    if { [regexp {^packages/([^ /]+)/} $path "" package_key] && \
	    [db_0or1row version_id_from_package_key "select version_id from apm_enabled_package_versions where package_key = '[db_quote $package_key]'"] } {
	api_set_public $version_id
    } else {
	api_set_public ""
    }
}

lappend context_bar_elements [list "" "API Browser"]
if { [info exists version_id] } {
    db_1row package_info_from_version_id "
        select package_name, package_key, version_name
        from apm_package_version_info
        where version_id = $version_id
    "
    lappend context_bar_elements [list "package-view?version_id=$version_id&kind=content" "$package_name $version_name"]
}

lappend context_bar_elements [file tail $path]

doc_body_append "
[ad_header [file tail $path]]
<h2>[file tail $path]</h2>

[eval ad_context_bar_ws_or_index $context_bar_elements]

<hr>

[api_script_documentation $path]

[ad_footer]
"