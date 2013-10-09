# /packages/acs-core/apm/admin-www/package-add-2.tcl

ad_page_contract {
    Adds a package to the package manager.
    
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id package-add-2.tcl,v 1.3.2.5 2000/07/22 08:32:43 ron Exp
} {
    package_key
    package_name
    package_url
    version_name
    version_url
    summary
    description:html
    description_format
    { owner_name:array }
    { owner_url:array }
    vendor
    vendor_url
    { install_p 0 }
}

set package_key [string tolower $package_key]

if { [regexp {[^a-z0-9-]} $package_key] } {
    lappend exceptions "The package key should contain only letters, numbers, and hyphens."
}


if { [db_string apm_count_packages_by_package_key {
    select count(*) from apm_packages where package_key = :package_key
}] } {
    lappend exceptions "A package with the key <tt>[ns_quotehtml $package_key]</tt> already exists."
}
if { [db_string apm_count_packages_by_package_url {
    select count(*) from apm_packages where package_url = :package_url
}] } {
    lappend exceptions "A package with the URL [ns_quotehtml $package_url] already exists."
}
if { [db_string apm_count_packages_by_version_url {
    select count(*) from apm_package_versions where version_url = :version_url
}] } {
    lappend exceptions "A version with the URL [ns_quotehtml $version_url] already exists."
}

foreach { name desc } {
    package_key "a package key"
    package_name "a name for your package"
    package_url "a package URL"
    version_name "the initial version for your package"
    version_url "a URL for the initial version of your package"
    summary "a summary of your package's functionality"
} {
    if { [empty_string_p [set $name]] } {
	lappend exceptions "You didn't provide $desc."
    }
}
if { [info exists exceptions] } {
	 ad_return_complaint [llength $exceptions] "<li>[join $exceptions "<li>\n"]"
    return
}


set package_id [db_nextval "apm_package_id_seq"]
set version_id [db_nextval "apm_package_version_id_seq"]

db_transaction {

    db_dml apm_package_create "
    insert into apm_packages(package_id, package_key, package_url)
    values(:package_id, :package_key, :package_url)
    "

    db_dml package_version_insert "
    insert into apm_package_versions(version_id, package_id, package_name, version_name, version_url,
            summary, description_format, release_date,
            vendor, vendor_url, description)
    values(:version_id, :package_id, :package_name, :version_name, :version_url,
	   :summary, :description_format, trunc(sysdate), :vendor, :vendor_url, :description)
    "

    # Insert information about the owners.
    set owner_index 1
    while { [info exists owner_name($owner_index)] && ![empty_string_p $owner_name($owner_index)] } {
	if { ![info exists owner_url($owner_index)] } {
	    set owner_url($owner_index) ""
	}
	set owner_name_index $owner_name($owner_index)
	set owner_url_index $owner_url($owner_index)
	
	db_dml apm_owner_insert {
	    insert into apm_package_owners (version_id, owner_name, owner_url, sort_key) 
	    values (:version_id, :owner_name_index, :owner_url_index, :owner_index)
	}
	incr owner_index
    }
} on_error {
    ad_return_error "Database Error" "
    I was unable to create your package for the following reason:

    <blockquote><pre>[ns_quotehtml $errmsg]</pre></blockquote>
    "
    return
}

if { $install_p } {
    if { [catch {
	apm_install_package_spec $version_id
    } error] } {
	ad_return_error "Error" "
	I was unable to create your package for the following reason:
	
	<blockquote><pre>[ns_quotehtml $error]</pre></blockquote>
	"
	return
    }
}    


db_release_unused_handles
ad_returnredirect "version-view?version_id=$version_id"
