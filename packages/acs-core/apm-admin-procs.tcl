ad_library {

    Definitions for the APM administration interface.

    @creation-date 19 Apr 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id $id$

}

proc_doc apm_serve_tarball {} { Serves a tarball (.apm file) for a package. } {
    ad_page_contract {
    } {
	version_id:naturalnum,notnull
    }
    ReturnHeaders "application/octet-stream"
    db_write_blob tarball_serve "
	select distribution_tarball from apm_package_versions where version_id = $version_id
    "
}

# This is similar to the proc above except that the package contents
# for a particular version are reconstructed on the fly using CVS

proc_doc apm_serve_archive {} { Serves a tarball (.apm file) for a package. } {
    ad_page_contract {
	version_id:naturalnum,notnull
    } {
	Serves an archive specified by version_id.
    }

    set files [db_list path_select "
	select path from apm_package_files where version_id = $version_id order by path
    "]
    if { [llength $files] == 0 } {
	return
    }

    db_1row "
    select p.package_key, p.package_url, v.*
    from   apm_packages p, apm_package_versions v
    where  v.version_id = :version_id
    and    v.package_id = p.package_id
    "

    set version_tag [apm_package_version_release_tag $package_key $version_name]
    ns_log "Notice" "Version tag is $version_tag"

    set tmpdir [ns_tmpnam]
    set cvs    [ad_parameter CvsPath vc]

    foreach file $files {
	set full_path [acs_package_root_dir $package_key]/$file
	set cvsroot   [vc_fetch_root $full_path]
	set tmpfile   "$tmpdir/$package_key/$file"
	
	file mkdir [file dirname $tmpfile]
	exec $cvs -q -d $cvsroot update -p -r $version_tag $full_path > $tmpfile
    }

    set tmpfile [ns_tmpnam]

    exec tar cf - -C $tmpdir $package_key | \
	    "[ad_parameter GzipExecutableDirectory "" /usr/local/bin]/gzip" -c > $tmpfile

    ad_returnfile 200 application/octet-stream $tmpfile

    file delete -force $tmpdir
    file delete $tmpfile
}

ad_proc apm_header { { -form "" } args } {

    # If the first element of the URL path is "admin", then
    # assume that this is an admin page. The magic string
    # "admin" should perhaps be configurable.
    #
    if { [string compare [lindex [ns_conn urlv] 0] "admin"] } {
	# Not an admin page; use the regular context bar.
	set context_bar_cmd ad_context_bar_ws
    } else {
	# An admin page; use the admin context bar.
	set context_bar_cmd ad_admin_context_bar
    }

    if { [llength $args] == 0 } {
	set args [list $context_bar_cmd "ACS Package Manager"]
    } else {
	set args [concat [list $context_bar_cmd [list "/admin/apm/" "ACS Package Manager"]] $args]
    }

    set title [lindex $args end]

    set header [ad_header $title ""]

    return "
    $header
    <form $form>
    <h3>$title</h3>
    [eval $args]
    <hr>
    "
}

proc_doc apm_shell_wrap { cmd } { Returns a command string, wrapped it shell-style (with backslashes) in case lines get too long. } {
    set out ""
    set line_length 0
    foreach element $cmd {
	if { $line_length + [string length $element] > 72 } {
	    append out "\\\n    "
	    set line_length 4
	}
	append out "$element "
	incr line_length [expr { [string length $element] + 1 }]
    }
    append out "\n"
}

proc_doc apm_serve_docs { conn dir } { Serves a documentation file, or index pages. } {
    set url [ns_conn url]

    if { [string compare [string range $url 0 [expr { [string length $dir] - 1 }]] $dir] } {
	# The URL doesn't seem to begin with the directory we expect! Wacky.
	ns_returnnotfound
	return
    }   

    # Clip the registered path off the URL.
    set url [string range $url [string length $dir] [string length $url]]
    if { [empty_string_p $url] } {
	# Requested something like "/apm/doc" - no trailing slash. Append one and redirect.
	ad_returnredirect "[ns_conn url]/"
	return
    }

    if { ![string compare $url "/"] } {
	# Requested something like "/apm/doc/" - serve up the index page.

	ReturnHeaders

	ns_write "[ad_header "Package Documentation"]
<h3>Package Documentation</h3>

[ad_context_bar_ws "Package Documentation"]
<hr>
<ul>
"
        set out ""

	db_foreach enabled_package_versions_select {
		select version_id, package_name, version_name, package_key, summary 
	        from apm_enabled_package_versions
	} {
	    set doc_files [apm_version_file_list -type "documentation" $version_id]
	    if { [llength $doc_files] == 0 } {
		append out "<li><b>$package_name $version_name</b> - $summary\n"
	    } elseif { [llength $doc_files] == 1 } {
		append out "<li><b><a href=\"$package_key/[file tail [lindex $doc_files 0]]\">$package_name $version_name</a></b> - $summary\n"
	    } else {
		append out "<li><b>$package_name $version_name</b> - $summary\n<ul>\n"
		foreach file $doc_files {
		    append out "<li><a href=\"$package_key/[file tail $file]\">[file tail $file]</a>\n"
		}
		append out "</ul>\n"
	    }
	}
	append out "</ul>\n[ad_footer]\n"
	ns_write $out
    } elseif { [regexp {^/([^/]+)/([^/]+)$} $url "" package_key tail] } {

        set bind_vars [ad_tcl_list_list_to_ns_set [list [list package_key $package_key] [list tail "%/$tail"]]]
	db_foreach "
            select path from apm_package_files
            where  version_id in (
                select version_id
                from   apm_packages p, apm_package_versions v
                where  p.package_id = v.package_id
                and    p.package_key = :package_key
                and    v.enabled_p = 't'
            )
            and file_type = 'documentation'
            and path like :tail
        " -bind $bind_vars {
	    if { ![info exists real_path] && ![string compare [lindex [split $path "/"] end] $tail] } {
		set real_path "[acs_root_dir]/$path"
	    }
	}

        ns_set free $bind_vars

	if { ![info exists real_path] } {
	    ns_returnnotfound
	    return
	}

	# Borrow from abstract-url-procs.tcl. Eventually the abstract URL stuff will push
	# this stuff out into its own procedure.
	set extension [file extension $real_path]
	if { $extension == ".tcl" } {
	    # Tcl file - use source.
	    
	    aurl_eval [list source $real_path]
	} elseif { $extension == ".adp" } {
	    if { ![aurl_eval [list ns_adp_parse -file $real_path] adp] } {
		return
	    }
	    set content_type [ns_set iget [ns_conn outputheaders] "content-type"]
	    if { $content_type == "" } {
		set content_type "text/html"
	    }
	    doc_return  200 $content_type $adp
	} else {
	    # Some other random kind of find - return it.
	    ad_returnfile 200 [ns_guesstype $real_path] $real_path
	}
    }
}
