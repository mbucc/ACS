# /packages/acs-core/apm/admin-www/packages-load-2.tcl

ad_page_contract {
    Loads a package from a URL into the package manager.

    @param url The url of the package to load.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id package-load-2.tcl,v 1.5.2.5 2000/10/16 21:15:02 bquinn Exp

} {
    url
}

proc apm_package_load_2_callback { message } {
    doc_body_append "$message<li>\n"
    doc_body_flush
}

doc_body_append "[apm_header -form "package-load.tcl" [list "package-load.tcl" "Load a New Package"] "View Package Contents"]

<ul>
<li>Downloading <a href=\"http://$url\">http://$url</a>...<li>
"
doc_body_flush

# Read the tarball (use wget, not ns_httpget, 'cause of that whole binary data issue).
if {[file exists "/usr/local/bin/wget"] } {
    set wget_cmd "/usr/local/bin/wget"
} elseif {[file exists "/usr/bin/wget"]} {
    set wget_cmd "/usr/bin/wget"
} else {
    ad_return_error "Command Not Found" "Your system does not appear to have <code>wget</code> in either <code>/usr/local/bin</code> or <code>/usr/bin</code>.  The package loader can not be
used without this program, so please install it and try again."
}

set tarball [ns_tmpnam]
set command [list $wget_cmd -qO- "http://$url" > $tarball]
ns_log "Notice" "Loading package with [join $command " "]"
if { [catch "exec $command"] || \
	![file exists $tarball] || [file size $tarball] == 0 } {
    doc_body_append "Unable to download. Please check your URL.</ul>\n[ad_footer]"
    return
}

set files [split [string trim \
	[exec [ad_parameter GzipExecutableDirectory "" /usr/local/bin]/gunzip -c $tarball | tar tf -] "\n"]]
doc_body_append "Done. Archive is [format "%.1f" [expr { [file size $tarball] / 1024.0 }]]KB, with [llength $files] files.<li>"
doc_body_flush

if { [llength $files] == 0 } {
    doc_body_append "The archive does not contain any files.\n[ad_footer]"
    return
}

set package_key [lindex [split [lindex $files 0] "/"] 0]

# Find that .info file.
foreach file $files {
    set components [split $file "/"]
    if { [string compare [lindex $components 0] $package_key] } {
	doc_body_append "All files in the archive must be contained in the same directory (corresponding to
the package's key). This is not the case, so the archive is not a valid APM file.\n[ad_footer]"
        return
    }
    if { [llength $components] == 2 && ![string compare [file extension $file] ".info"] } {
	if { [info exists info_file] } {
	    doc_body_append "The archive contains more than one <tt>package/*/*.info</tt> file, so it is not a valid APM file.</ul>\n[ad_footer]"
	    return
	}
	set info_file $file
    }
}

if { ![info exists info_file] || [regexp {[^a-zA-Z0-9\-\./_]} $info_file] } {
    doc_body_append "The archive does not contain a <tt>*/*.info</tt> file, so it is not a valid APM file.</ul>\n[ad_footer]"
    return
}

doc_body_append "Extracting the .info file (<tt>$info_file</tt>)...<li>"
set tmpdir [ns_tmpnam]
file mkdir $tmpdir
exec sh -c "cd $tmpdir ; [ad_parameter GzipExecutableDirectory "" /usr/local/bin]/gunzip -c $tarball | tar xf - $info_file"

db_transaction {
    # Register the package by loading the .info file.
    set version_id [apm_register_package -callback apm_package_load_2_callback "$tmpdir/$info_file"]
    if { ![empty_string_p $version_id] } {
	doc_body_append "Loading the tarball into the database...<li>"
	set distribution_url "http://$url"
	db_dml loading_tarball {
	    update apm_package_versions
                set    distribution_tarball = empty_blob(),
                       distribution_url = :distribution_url,
                       distribution_date = sysdate
                where  version_id = :version_id
                returning distribution_tarball into :1
	} -blob_files [list $tarball]
    }
}

db_1row apm_get_package_info {
    select version_id, package_name, version_name from apm_package_version_info where version_id = :version_id
}

doc_body_append "Done.

<p><a href=\"version-view.tcl?version_id=$version_id\">View information about $package_name $version_name</ul>
[ad_footer]
"