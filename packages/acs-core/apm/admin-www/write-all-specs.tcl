ad_page_contract {
    Generates package specs for every enabled version.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id write-all-specs.tcl,v 1.3.2.3 2000/07/21 03:55:49 ron Exp
} {
}

doc_body_append "[apm_header "Generate Package Specifications"]

<ul>
"

db_foreach apm_get_all_packages {
    select version_id, version_name, package_name, distribution_url
    from   apm_package_versions
    where  installed_p = 't'
    order by upper(package_name)
} {
    if { [empty_string_p $distribution_url] } {
	doc_body_append "<li>$package_name $version_name... "
	if { [catch { apm_install_package_spec $version_id } error] } {
	    doc_body_append "error: $error\n"
	} else {
	    doc_body_append "done.\n"
	}
	doc_body_flush
    } else {
	doc_body_append "<li>$package_name $version_name was not generated locally.\n"
    }
}

db_release_unused_handles
doc_body_append "</ul>

<a href=\"\">Return to the Package Manager</a>

[ad_footer]"

