ad_page_contract { 
    Installs or upgrades to a new version of a package.
    
    @param cvs_p Import into cvs?
    @param sql_file_id This should be a Tcl list of file_ids matching SQL data models to load.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-install-4.tcl,v 1.6.2.5 2000/10/16 18:44:04 bquinn Exp
} {
    {version_id:integer}
    cvs_p
    {sql_file_id:optional,multiple [list]}
}

db_1row apm_package_by_version_id {
    select package_name, version_name, package_key, package_id 
    from apm_package_version_info where version_id = :version_id
}

doc_body_append "[apm_header "Install $package_name $version_name"]

"

if { $cvs_p } {
    # Verify that the package really has been checked in. We'll look at the .info
    # file in the package directory - is the version name correct?

    set spec_file "[acs_package_root_dir $package_key]/[lindex [apm_version_file_list -type "package_spec" $version_id] 0]"

    if { ![file exists $spec_file] } {
	doc_body_append "The package specification file has not been properly installed in
$spec_file.
Most probably this means that you did not follow the instructions on the
previous page - please <a href=\"javascript:history.back()\">go back and try again</a>.

[ad_footer]
"
        return
    }

    if { [catch {
	array set version [apm_read_package_info_file $spec_file]
    } error] } {
	doc_body_append "Unable to parse the package specification,
[ad_make_relative_path $spec_file]: $error.

[ad_footer]
"
        return
    }

    if { ![string equal $version(name) $version_name] } {
	doc_body_append "It appears that a different version of the package, version $version(name), is still installed (according to the package specification file, $spec_file).
Most probably this means that you did not follow the instructions on the
previous page - please <a href=\"javascript:history.back()\">go back and try again</a>.

[ad_footer]
"
        return       
    }
}

doc_body_append "<ul>\n"
if { [llength $sql_file_id] > 0 } {
    doc_body_append "<li>Installing the data model...\n<ul>\n"
    db_foreach apm_data_model_files_load "
        select path
        from   apm_package_files
        where  file_id in ([join $sql_file_id ","])
        order  by path
    " {
	doc_body_append "<li>Loading $path in SQL*Plus...\n<blockquote><pre>"
	doc_body_flush
	doc_body_append [ns_quotehtml [apm_load_in_sqlplus "[acs_package_root_dir $package_key]/$path"]]
	doc_body_append "</pre></blockquote>\n"
	doc_body_flush
    }
    doc_body_append "</ul>\n"
}

doc_body_append "<li>Marking the package as installed and enabled.\n"

db_dml apm_set_installed {
    update apm_package_versions
    set    installed_p = decode(version_id, :version_id, 't', 'f'),
           data_model_loaded_p = 't'
    where  package_id = :package_id
}
apm_enable_version $version_id

doc_body_append "<li>Done.
</ul>

[ad_footer]
"

