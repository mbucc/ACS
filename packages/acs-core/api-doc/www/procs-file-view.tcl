ad_page_contract {
    Displays procs in a Tcl library file.

    @cvs-id procs-file-view.tcl,v 1.1.4.6 2000/07/21 03:55:41 ron Exp
} {
    version_id:optional
    public_p:optional
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

set dimensional_list {
    {
	public_p "Publicity:" 1 {
	    { 1 "Public Only" }
	    { 0 "All" }
	}
    }
}

lappend context_bar_elements [list "" "API Browser"]
if { [info exists version_id] } {
    db_1row package_info_from_package_id "
        select package_name, package_key, version_name
        from apm_package_version_info
        where version_id = $version_id
    "
    lappend context_bar_elements [list "package-view?version_id=$version_id" "$package_name $version_name"]
}

lappend context_bar_elements [file tail $path]

doc_body_append "
[ad_header [file tail $path]]
<h2>[file tail $path]</h2>

[eval ad_context_bar_ws_or_index $context_bar_elements]

<hr>

"

doc_body_append "
<table align=right><tr><td>[ad_dimensional $dimensional_list]</td></tr></table>

[api_library_documentation $path]
<br clear=all>
"

set proc_doc_list [list]

set public_p [ns_queryget public_p]

if { [nsv_exists api_proc_doc_scripts $path] } {
    doc_body_append "<h3>Procedures in this file</h3>\n<ul>"
    foreach proc [lsort [nsv_get api_proc_doc_scripts $path]] {
	if { $public_p } {
	    array set doc_elements [nsv_get api_proc_doc $proc]
	    if { !$doc_elements(public_p) } {
		continue
	    }
	}
	doc_body_append "<li>[api_proc_pretty_name -link $proc]"
    }   
    doc_body_append "</ul>
    <h3>Detailed information</h3>"

    foreach proc [lsort [nsv_get api_proc_doc_scripts $path]] {
	if { $public_p } {
	    array set doc_elements [nsv_get api_proc_doc $proc]
	    if { !$doc_elements(public_p) } {
		continue
	    }
	}

	lappend proc_doc_list "<table width=100%><tr><td bgcolor=#e4e4e4>\n[api_proc_documentation $proc]\n</td></tr></table>"
    }
}

doc_body_append "

[join $proc_doc_list "\n\n<p>\n\n"]

[ad_footer]

"
