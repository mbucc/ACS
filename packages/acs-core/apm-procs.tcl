ad_library {

    Routines used by the package manager.

    @creation-date 13 Apr 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id apm-procs.tcl,v 1.16.2.26 2000/09/28 21:58:03 bquinn Exp
}

#####
#
# Note: All APIs should be considered private and subject to change.
#
#####

#####
#
# NSV arrays used by the package_manager: (note that all paths are relative
# to [acs_path_root] unless otherwise indicated)
#
#     apm_version_properties($info_file_path)
#
#         Contains a list [list $mtime $properties_array], where $properties_array
#         is a cached copy of the version properties array last returned by
#         [apm_read_package_info_file $info_file_path], and $mtime is the
#         modification time of the $info_file_path when it was last examined.
#
#         This is a cache for apm_read_package_info_file.
#
#     apm_library_mtime($path)
#
#         The modification time of $file (a *-procs.tcl or *-init.tcl file) 
#         when it was last loaded.
#
#     apm_version_procs_loaded_p($version_id)
#     apm_version_init_loaded_p($version_id)
#
#         1 if the *-procs.tcl and *-init.tcl files (respectively) have been
#         loaded for package version $version_id.
#
#     apm_vc_status($path)
#
#         A cached result from apm_fetch_cached_vc_status (of the form
#         [list $mtime $path]) containing the last-known CVS status of
#         $path.
#
#     apm_properties(reload_level)
#
#         The current "reload level" for the server.
#
#     apm_reload($reload_level)
#
#         A list of files which need to be loaded to bring the current interpreter
#         up to reload level $reload_level from level $reload_level - 1.
#
#     apm_reload_watch($path)
#
#         Indicates that $path is a -procs.tcl file which should be examined
#         every time apm_reload_any_changed_libraries is invoked, to see whether
#         it has changed since last loaded. The path starts at acs_root_dir.
#
# RELOADING VOODOO
#
#     To allow for automatically reloading of Tcl libraries, we introduce the
#     concept of a server-wide "reload level" (starting at zero) stored in
#     the apm_properties(reload_level) NSV array entry. Whenever we determine
#     we want to have all interpreters source a particular -procs.tcl file,
#     we:
#
#         1) Increment apm_properties(reload_level), as a signal to each
#            interpreter that it needs to source some new -procs.tcl files
#            to bring itself up to date.
#         2) Set apm_reload($reload_level), where $reload_level is the new
#            value of apm_properties(reload_level) set in step #1, to the
#            list of files which actually need to be sourced.
#
#     Each interpreter maintains its private, interpreter-specific reload level
#     as a proc named apm_reload_level_in_this_interpreter. Every time the
#     request processor sees a request, it invokes
#     apm_reload_any_changed_libraries, which compares the server-wide
#     reload level to the interpreter-private one. If it notes a difference,
#     it reloads the set of files necessary to bring itself up-to-date (i.e.,
#     files noted in the applicable entries of apm_reload).
#
#     Example:
#
#         - The server is started. apm_properties(reload_level) is 0.
#         - I modify /packages/acs-core/utilities-procs.tcl.
#         - Through the package manager GUI, I invoke
#           apm_mark_version_for_reload. It notices that utilities-procs.tcl
#           has changed. It increments apm_properties(reload_level) to 1,
#           and sets apm_reload(1) to [list "packages/acs-core/utilities-procs.tcl"].
#         - A request is handled in some other interpreter, whose reload
#           level (as returned by apm_reload_level_in_this_interpreter)
#           is 0. apm_reload_any_changed_libraries notes that
#           [apm_reload_level_in_this_interpreter] != [nsv_get apm_properties reload_level],
#           so it sources the files listed in apm_reload(1) (i.e., utilities-procs.tcl)
#           and redefines apm_reload_level_in_this_interpreter to return 1.
#
#####

proc_doc apm_file_type_keys {} {

    Returns a list of valid file type keys.

} {
    return [util_memoize [list db_list unused "select file_type_key from apm_package_file_types"]]
}

proc_doc apm_load_xml_packages {} {

    Loads XML packages into the running interpreter, if they're not
    already there. We need to load these packages once per connection,
    since AOLserver doesn't seem to deal with packages very well.

} {
    global ad_conn
    if { ![info exists ad_conn(xml_loaded_p)] } {
	foreach file [glob "[acs_package_root_dir acs-core]/xml-*-procs.tcl"] {
	    apm_source $file
	}
	set ad_conn(xml_loaded_p) 1
    }

    package require xml 1.9
}

proc_doc apm_required_attribute_value { element attribute } {

    Returns an attribute of an element, throwing and error if the attribute
    is not set.

} {
    set value [dom::element getAttribute $element $attribute]
    if { [empty_string_p $value] } {
	error "Required attribute \"$attribute\" missing from <[dom::node cget $element -nodeName]>"
    }
    return $value
}

proc_doc apm_read_package_info_file { path } {

    Reads a .info file, returning an array containing the following items:

    <ul>
    <li><code>path</code>: a path to the file read
    <li><code>mtime</code>: the mtime of the file read
    <li><code>provides</code> and <code>$requires</code>: lists of dependency
    information, containing elements of the form <code>[list $url $version]</code>
    <li><code>owners</code>: a list of owners containing elements of the form
    <code>[list $url $name]</code>
    <li><code>files</code>: a list of files in the package,
    containing elements of the form <code>[list $path
    $type]</code>
    <li><code>includes</code>: a list of included packages
    <li>Element and attribute values directly from the XML specification:
    <code>package.key</code>,
    <code>package.url</code>,
    <code>name</code> (the version name, e.g., <code>3.3a1</code>,
    <code>url</code> (the version URL),
    <code>package-name</code>,
    <code>option</code>,
    <code>summary</code>,
    <code>description</code>,
    <code>distribution</code>,
    <code>release-date</code>,
    <code>vendor</code>,
    <code>group</code>,
    <code>vendor.url</code>, and
    <code>description.format</code>.

    </ul>
    
    This routine will typically be called like so:
    
    <blockquote><pre>array set version_properties [apm_read_package_info_file $path]</pre></blockquote>

    to populate the <code>version_properties</code> array.

    <p>If the .info file cannot be read or parsed, this routine throws a
    descriptive error.

} {
    global ad_conn

    # If the .info file hasn't changed since last read (i.e., has the same
    # mtime), return the cached info list.
    set mtime [file mtime $path]
    if { [nsv_exists apm_version_properties $path] } {
	set cached_version [nsv_get apm_version_properties $path]
	if { [lindex $cached_version 0] == $mtime } {
	    return [lindex $cached_version 1]
	}
    }

    # Set the path and mtime in the array.
    set properties(path) $path
    set properties(mtime) $mtime

    apm_load_xml_packages

    ns_log "Notice" "Reading specification file at $path"

    set file [open $path]
    set xml_data [read $file]
    close $file

    set tree [dom::DOMImplementation parse $xml_data]
    set package [dom::node cget $tree -firstChild]
    if { ![string equal [dom::node cget $package -nodeName] "package"] } {
	error "Expected <package> as root node"
    }
    set properties(package.key) [apm_required_attribute_value $package key]
    set properties(package.url) [apm_required_attribute_value $package url]

    set versions [dom::element getElementsByTagName $package version]
    if { [llength $versions] != 1 } {
	error "Package must contain exactly one <version> node"
    }
    set version [lindex $versions 0]
    
    set properties(name) [apm_required_attribute_value $version name]
    set properties(url) [apm_required_attribute_value $version url]

    # Set an entry in the properties array for each of these tags.
    foreach property_name { package-name option summary description distribution release-date vendor group } {
	set node [lindex [dom::element getElementsByTagName $version $property_name] 0]
	if { ![empty_string_p $node] } {
	    set properties($property_name) [dom::node cget [dom::node cget $node -firstChild] -nodeValue]
	} else {
	    set properties($property_name) ""
	}
    }

    # Set an entry in the properties array for each of these attributes:
    #
    #   <vendor url="...">           -> vendor.url
    #   <description format="...">   -> description.format

    foreach { property_name attribute_name } {
	vendor url
	description format
    } {
	set node [lindex [dom::element getElementsByTagName $version $property_name] 0]
	if { ![empty_string_p $node] } {
	    set properties($property_name.$attribute_name) [dom::element getAttribute $node $attribute_name]
	} else {
	    set properties($property_name.$attribute_name) ""
	}
    }

    # We're done constructing the properties array - save the properties into the
    # moby array which we're going to return.

    set properties(properties) [array get properties]

    # Build lists of the services provided by and required by the package.

    set properties(provides) [list]
    set properties(requires) [list]

    foreach dependency_type { provides requires } {
	foreach node [dom::element getElementsByTagName $version $dependency_type] {
	    set service_url [apm_required_attribute_value $node url]
	    set service_version [apm_required_attribute_value $node version]
	    lappend properties($dependency_type) [list $service_url $service_version]
	}
    }

    # Build a list of the files contained in the package.

    set properties(files) [list]

    foreach node [dom::element getElementsByTagName $version "files"] {
	foreach file_node [dom::element getElementsByTagName $node "file"] {
	    set file_path [apm_required_attribute_value $file_node path]
	    set type [dom::element getAttribute $file_node type]
	    # Validate the file type: it must be null (unknown type) or
	    # some value in [apm_file_type_keys].
	    if { ![empty_string_p $type] && [lsearch -exact [apm_file_type_keys] $type] < 0 } {
		error "Invalid file type \"$type\""
	    }
	    lappend properties(files) [list $file_path $type]
	}
    }

    # Build a list of the package's owners (if any).

    set properties(owners) [list]

    foreach node [dom::element getElementsByTagName $version "owner"] {
	set url [dom::element getAttribute $node url]
	set name [dom::node cget [dom::node cget $node -firstChild] -nodeValue]
	lappend properties(owners) [list $url $name]
    }

    # Build a list of the packages included by this package (if any).

    set properties(includes) [list]

    foreach node [dom::element getElementsByTagName $version "include"] {
	lappend properties(includes) [dom::element getAttribute $node url]
    }

    # Serialize the array into a list.
    set return_value [array get properties]

    # Cache the property info based on $mtime.
    nsv_set apm_version_properties $path [list $mtime $return_value]

    return $return_value
}

proc_doc apm_dummy_callback { string } {

    A dummy callback routine which does nothing.

} {
    # Do nothing!
}

proc_doc apm_package_info_file_path { package_key } {

    Returns the path to a .info file in a package directory, or throws an
    error if none exists. Currently, only $package_key.info is recognized
    as a specification file.

} {
    set path "[acs_package_root_dir $package_key]/$package_key.info"
    if { [file exists $path] } {
	return $path
    }
    error "The /packages/$package_key directory does not contain a package specification file ($package_key.info)."
}

ad_proc apm_register_package { { -callback apm_dummy_callback } path } {

    Registers a new package and/or version in the database, returning the version_id.
    If $callback is provided, periodically invokes this procedure with a single argument
    containing a human-readable (English) status message.

    <p>This routine throws an error if the specification file is nonexistent
    or invalid.

} {
    # Note: We use the Tcl proc "#" as a dummy do-nothing callback proc.
    apm_callback_and_log $callback "Reading the configuration file at $path..."

    array set version [apm_read_package_info_file $path]

    db_transaction {
	set package_key $version(package.key)
	set package_url $version(package.url)

	# If the package doesn't already exist in apm_packages, insert a new row.
	if { ![db_0or1row apm_package_get {
	    select package_id
	    from apm_packages 
	    where package_url = :package_url
	}]} {
	    set package_id [db_nextval "apm_package_id_seq"]
	    set dml_stm "
                )"
	    db_dml package_insert {
		insert into apm_packages(package_id, package_key, package_url)
                values(:package_id, :package_key, :package_url)
	    }
        }

	
	set package_id $package_id
	set package_name $version(package-name)
	set version_name $version(name)
	set version_url $version(url)
	set summary $version(summary)
	set description_format $version(description.format)
	set description $version(description)
	set release_date $version(release-date)
	set vendor $version(vendor)
	set vendor_url $version(vendor.url)
	# Prepare a list of column names and values.
	set columns [list \
		[list package_id :package_id] \
		[list package_name :package_name] \
		[list version_name :version_name] \
		[list summary :summary] \
		[list description_format :description_format] \
		[list release_date :release_date] \
		[list vendor :vendor] \
		[list vendor_url :vendor_url]]

	# If there is a package group, add it to the insert.
	set package_group $version(group)
	if { ![empty_string_p $package_group] } {
	    lappend columns [list package_group :package_group]
	}
	    
	# If the version already exists in apm_package_versions, update it;
	# otherwise, insert a new version.
	if { [db_0or1row version_exists_p {
	    select version_id 
	    from apm_package_versions 
	    where version_url = :version_url
	} ]} {
	    lappend columns [list description :description]
	    set column_sql [list]
	    foreach column $columns {
		lappend column_sql "[lindex $column 0] = [lindex $column 1]"
	    }
	    db_dml version_update "update apm_package_versions set [join $column_sql ", "] where version_id = :version_id" 
	} else {
	    set version_id [db_nextval "apm_package_version_id_seq"]
	    lappend columns [list version_id :version_id]
	    lappend columns [list version_url :version_url]
	    lappend columns [list enabled_p "'f'"]
	    lappend columns [list installed_p "'f'"]
	    lappend columns [list description :description]
	    set column_name_sql [list]
	    set column_value_sql [list]
	    foreach column $columns {
		lappend column_name_sql [lindex $column 0]
		lappend column_value_sql [lindex $column 1]
	    }
	    db_dml version_insert "
		insert into apm_package_versions([join $column_name_sql ","]) 
		values([join $column_value_sql ","])" 
	}
	
	# Note that we do a bunch of delete/inserts below - this is acceptable because
	# nothing ever references apm_package_(dependencies|owners|files|includes) -
	# the numeric primary keys exist solely for the use of the administration
	# interface.

	# Delete and reinsert dependencies.

	db_dml dependency_delete "delete from apm_package_dependencies where version_id = :version_id"
	foreach dependency_type { provides requires } {
	    foreach item $version($dependency_type) {

		set item_at_0 [lindex $item 0]
		set item_at_1 [lindex $item 1]

		db_dml dependency_insert "
                    insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_url, service_version)
                    values(apm_package_dependency_id_seq.nextval, :version_id, :dependency_type, :item_at_0, :item_at_1)
                "
            }
	}

	# Delete and reinsert owners (in sorted order, to preserve package
	# developers' fragile egos).
	set counter 0
	db_dml owner_delete "delete from apm_package_owners where version_id = :version_id"
	foreach item $version(owners) {
	    incr counter
	    set item_at_0 [lindex $item 0]
	    set item_at_1 [lindex $item 1]

	    db_dml owner_insert {
                insert into apm_package_owners(version_id, owner_url, owner_name, sort_key)
                values(:version_id, :item_at_0, :item_at_1, :counter)
            }
	}

	# Delete and reinsert files.
	db_dml files_delete "delete from apm_package_files where version_id = :version_id"
	foreach item $version(files) {

	    set item_at_0 [lindex $item 0]
	    set item_at_1 [lindex $item 1]

	    db_dml files_insert {
                insert into apm_package_files(file_id, version_id, path, file_type)
                values(apm_package_file_id_seq.nextval, :version_id, :item_at_0, :item_at_1)
            }
	}

	# Delete and reinsert includes.
	db_dml includes_delete "delete from apm_package_includes where version_id = :version_id"
	foreach item $version(includes) {

	    db_dml includes_insert {
	        insert into apm_package_includes(include_id, version_id, version_url)
                values(apm_package_include_id_seq.nextval, :version_id, :item)
            }
	}

	apm_callback_and_log $callback "Registered $version(package-name), version $version(name)."
    }
    return $version_id
}

ad_proc apm_callback_and_log { { -severity Notice } callback message } {

    Executes the $callback callback routine with $message as an argument,
    and calls ns_log with the given $severity.

} {
    $callback $message
    ns_log $severity $message
}   

ad_proc apm_register_new_packages { { -callback apm_dummy_callback } } {

    Looks for unregistered packages in the packages directory,
    registering them in the database if found.

} {
    ns_log "Notice" "Scanning for new packages..."

    # Obtain paths and mtimes for the spec files of all installed packages, in order
    # to avoid reading spec files which haven't changed.
    db_foreach package_info "
        select package_key, spec_file_mtime
        from apm_packages
    " {
	set spec_file_paths($package_key) "[acs_package_root_dir $package_key]/$package_key.info"
	set spec_file_mtimes($package_key) $spec_file_mtime
    }

    # Loop through all directories in the /packages directory, searching each for a
    # .info file.
    set n_registered_packages 0
    foreach dir [lsort [glob -nocomplain "[acs_root_dir]/packages/*"]] {
	set package_key [file tail $dir]

	if { ![file isdirectory $dir] || [apm_ignore_file_p $dir] } {
	    apm_callback_and_log $callback "Skipping $package_key."
	    continue
	}

	# Locate the .info file for this package.
	if { [catch { set info_file [apm_package_info_file_path $package_key] } error] } {
	    apm_callback_and_log -severity Warning $callback "Unable to locate specification file for package $package_key: $error"
	    continue
	}

	# If the mtime for this package hasn't changed since the last time we
	# examined it, don't bother reregistering it.
	
	if { [info exists spec_file_paths($package_key)] && \
		[file isfile $spec_file_paths($package_key)] && \
		[file mtime $spec_file_paths($package_key)] == $spec_file_mtimes($package_key) } {
	    apm_callback_and_log $callback "$spec_file_paths($package_key) has not changed; skipping."
	    continue
	}

	# Try to register the .info file in the database.
	if { [catch { set version_id [apm_register_package -callback $callback $info_file] } error] } {
	    apm_callback_and_log -severity Error $callback "Unable to register package $package_key: $error"

	    # Ensure that the package is not marked as installed, since we've established
	    # that there is no valid .info file in the filesystem!

	    db_dml package_mark_uninstalled {
                update apm_package_versions
                set    installed_p = 'f'
                where  package_id in (select package_id from apm_packages
                                      where package_key = :package_key)
	    }

	} else {
	    incr n_registered_packages

	    array set version [apm_read_package_info_file $info_file]
	    set version_mtime $version(mtime)

	    # Remember that we've examined this .info file.
	    db_dml package_mark_info_examined {
                update apm_packages
                set spec_file_mtime = :version_mtime
                where package_key = :package_key
            }

	    # Mark this version of the package as installed, and other versions as un-installed.
	    db_dml package_version_mark_installed {
                update apm_package_versions
                set    installed_p = decode(version_id, :version_id, 't', 'f')
                where  package_id in (select package_id from apm_packages
                                      where package_key = :package_key)
	    }
	}
    }

    db_release_unused_handles

    if { $n_registered_packages == 0 } {
	ns_log "Notice" "No new packages found."
    }
}

proc_doc apm_version_loaded_p { version_id } {

    Returns 1 if a version of a package has been loaded and initialized, or 0 otherwise.

} {
    return [nsv_exists apm_version_init_loaded_p $version_id]
}

ad_proc apm_version_file_list { { -type "" } version_id } {

    Returns a list of paths to files of a given type (or all files, if
    $type is not specified) in a version.

} {
    if { ![empty_string_p $type] } {
	set type_sql "and file_type = :type"
    } else {
	set type_sql ""
    }
    return [db_list path_select "
        select path from apm_package_files
        where  version_id = :version_id
        $type_sql order by path
    "]
}

proc_doc apm_generate_tarball { version_id } {
    
    Generates a tarball for a version, placing it in the version's distribution_tarball blob.
    
} {
    set files [apm_version_file_list $version_id]
    
    set tmpfile [ns_tmpnam]
    
    db_1row package_key_select "select package_key from apm_package_version_info where version_id = :version_id"

    # Generate a command like:
    #
    #   tar cf - -C /web/arsdigita/packages acs-core/00-proc-procs.tcl \
    #                 -C /web/arsdigita/packages 10-database-procs.tcl ...  \
    #     | gzip -c > $tmpfile
    #
    # Note that -C changes the working directory before compressing the next
    # file; we need this to ensure that the tarballs are relative to the
    # package root directory ([acs_root_dir]/packages).

    set cmd [list exec tar cf -]
    foreach file $files {
	lappend cmd -C "[acs_root_dir]/packages"
	lappend cmd "$package_key/$file"
    }

    lappend cmd "|" "[ad_parameter GzipExecutableDirectory "" /usr/local/bin]/gzip" -c ">" $tmpfile
    eval $cmd

    # At this point, the APM tarball is sitting in $tmpfile. Save it in the database.

    db_dml apm_tarball_insert {
        update apm_package_versions
           set distribution_tarball = empty_blob(),
               distribution_url = null,
               distribution_date = sysdate
         where version_id = :version_id
     returning distribution_tarball into :1
    } -blob_files [list $tmpfile]

    file delete $tmpfile
}

proc_doc apm_mark_version_for_reload { version_id { file_info_var "" } } {

    Examines all tcl_procs files in package version $version_id; if any have
    changed since they were loaded, marks (in the apm_reload array) that
    they must be reloaded by each Tcl interpreter (using the
    apm_reload_any_changed_libraries procedure).
    
    <p>Saves a list of files that have changed (and thus marked to be reloaded) in
    the variable named <code>$file_info_var</code>, if provided. Each element
    of this list is of the form:

    <blockquote><pre>[list $file_id $path]</pre></blockquote>

} {
    if { ![empty_string_p $file_info_var] } {
	upvar $file_info_var file_info
    }
    set files [apm_version_file_list -type "tcl_procs" $version_id]

    db_1row package_key_select "select package_key from apm_package_version_info where version_id = :version_id"

    set changed_files [list]
    set file_info [list]

    db_foreach file_info {
        select file_id, path
        from   apm_package_files
        where  version_id = :version_id
        and    file_type = 'tcl_procs'
        order by path
    } {
	set full_path "[acs_package_root_dir $package_key]/$path"

	set relative_path "packages/$package_key/$path"

	# If the file exists, and either has never been loaded or has an mtime
	# which differs the mtime it had when last loaded, mark to be loaded.
	if { [file isfile $full_path] } {
	    set mtime [file mtime $full_path]
	    if { ![nsv_exists apm_library_mtime $relative_path] || \
		    [nsv_get apm_library_mtime $relative_path] != $mtime } {
		lappend changed_files $relative_path
		lappend file_info [list $file_id $relative_path]
		nsv_set apm_library_mtime $relative_path $mtime
	    }
	}
    }

    if { [llength $changed_files] > 0 } {
	set reload [nsv_incr apm_properties reload_level]
	nsv_set apm_reload $reload $changed_files
    }
}

proc_doc apm_version_load_status { version_id } {

    If a version needs to be reloaded (i.e., a <code>-procs.tcl</code> has changed
    or been added since the version was loaded), returns "needs_reload".
    If the version has never been loaded, returns "never_loaded". If the
    version is up-to-date, returns "up_to_date".
    
} {
    # See if the version was never loaded.
    if { ![apm_version_loaded_p $version_id] } {
	return "never_loaded"
    }

    db_1row package_id_and_key_select {
        select package_id, package_key
        from apm_package_version_info
        where version_id = :version_id
    }

    foreach file [apm_version_file_list -type "tcl_procs" $version_id] {
	# If $file has never been loaded, i.e., it has been added to the version
	# since the version was initially loaded, return needs_reload.
	if { ![nsv_exists apm_library_mtime "packages/$package_key/$file"] } {
	    return "needs_reload"
	}

	set full_path "[acs_package_root_dir $package_key]/$file"
	# If $file had a different mtime when it was last loaded, return
	# needs_reload. (If the file should exist but doesn't, just skip it.)
	if { [file exists $full_path] && \
		[file mtime $full_path] != [nsv_get apm_library_mtime "packages/$package_key/$file"] } {
	    return "needs_reload"
	}
    }

    return "up_to_date"
}

proc_doc apm_load_libraries { procs_or_init } {

    Loads all -procs.tcl (if $procs_or_init is "procs") or -init.tcl (if $procs_or_init is
    "init") files into the current interpreter for installed, enabled packages. Only loads
    files which have not yet been loaded. This is intended to be called only during server
    initialization (since it loads libraries only into the running interpreter, as opposed
    to in *all* active interpreters).

} {
    if { ![string equal $procs_or_init "procs"] && ![string equal $procs_or_init "init"] } {
	error "Argument to apm_load_libraries must be \"procs\" or \"init\""
    }

    ns_log "Notice" "Loading packages' *-$procs_or_init.tcl files..."

    set file_type tcl_$procs_or_init

    # Load in sorted order of package_key and path.
    set files [db_list packages_load {
        select 'packages/' || package_key || '/' || path
        from   apm_package_files f, apm_package_version_info v
        where  f.version_id = v.version_id
        and    v.enabled_p = 't'
        and    f.file_type = :file_type
        order by package_key, path
    }]

    # Release all outstanding database handles (since the file we're sourcing
    # might be using the ns_db database API as opposed to the new db_* API).
    db_release_unused_handles

    # This will be the first time loading for each of these files (since if a
    # file has already been loaded, we just skip it in the loop below).
    global apm_first_time_loading_p
    set apm_first_time_loading_p 1

    foreach file $files {
	# If the file has never been loaded, source it.
	if { ![nsv_exists apm_library_mtime $file] } {
	    if { [file exists "[acs_root_dir]/$file"] } {
		ns_log "Notice" "Loading $file..."

		# Remember that we've loaded the file.
		apm_source "[acs_root_dir]/$file"
		nsv_set apm_library_mtime $file [file mtime "[acs_root_dir]/$file"]

		# Release outstanding database handles (in case this file
		# used the db_* database API and a subsequent one uses
		# ns_db).
		db_release_unused_handles

		ns_log "Notice" "Loaded $file."
	    } else {
		ns_log "Error" "Unable to load $file - file is marked as contained in a package but is not present in the filesystem"
	    }
	} else {
	    ns_log Notice "Skipping $file - it has already been loaded"
	}
    }

    unset apm_first_time_loading_p

    # Remember that we've now loaded every enabled version.
    db_foreach version_id "
        select version_id
        from apm_package_version_info
        where enabled_p = 't'
    " {
	nsv_set apm_version_${procs_or_init}_loaded_p $version_id 1
    }
}

ad_proc ad_find_all_files {
    {
	-include_backup 0
	-include_dirs 0
	-max_depth 10
    }
    path
} {

    Returns a list of full paths to all files under $path in the directory tree
    (descending the tree to a depth of up to $max_depth). Includes backup files only
    if $include_backup is true; includes directories in the returned list only if
    $include_dirs is true. Ignores all files for which apm_ignore_file_p returns
    true. Clients should not depend on the order of files returned.

} {
    # Use the examined_files array to track files that we've examined.
    array set examined_files [list]

    # A list of files that we will return (in the order in which we
    # examined them).
    set files [list]

    # A list of files that we still need to examine.
    set files_to_examine [list $path]

    # Perform a breadth-first search of the file tree. For each level,
    # examine files in $files_to_examine; if we encounter any directories,
    # add contained files to $new_files_to_examine (which will become
    # $files_to_examine in the next iteration).
    while { [incr max_depth -1] > 0 && [llength $files_to_examine] != 0 } {
	set new_files_to_examine [list]
	foreach file $files_to_examine {
	    # Only examine the file if we haven't already. (This is just a safeguard
	    # in case, e.g., Tcl decides to play funny games with symbolic links so
	    # we end up encountering the same file twice.)
	    if { ![info exists examined_files($file)] } {
		# Remember that we've examined the file.
		set examined_files($file) 1

		# If (a) we shouldn't ignore the file, and (b) either it's not a
		# backup file or we specifically want to include backup files in
		# our list...
		if { ![apm_ignore_file_p $file] && \
			($include_backup == 1 || ![apm_backup_file_p $file]) } {
		    # If it's a file, add to our list. If it's a
		    # directory, add its contents to our list of files to
		    # examine next time.
		    if { [file isfile $file] } {
			lappend files $file
		    } elseif { [file isdirectory $file] } {
			if { $include_dirs == 1 } {
			    lappend files $file
			}
			set new_files_to_examine [concat $new_files_to_examine [glob -nocomplain "$file/*"]]
		    }
		}
	    }
	}
	set files_to_examine $new_files_to_examine
    }
    return $files
}

proc_doc apm_pretty_name_for_file_type { type } {

    Returns the pretty name corresponding to a particular file type key
    (memoizing to save a database hit here and there).

} {
    return [util_memoize [list db_string pretty_name_select "
        select pretty_name
        from apm_package_file_types
        where file_type_key = :type
    " -default "Unknown" -bind [list type $type]]]
}

proc_doc apm_load_in_sqlplus { path } {

    Executes a file in SQL*Plus, returning any output or error.
    
} {
    global env

    set default_pool [ns_config "ns/server/[ns_info server]/db" DefaultPool]
    set user_pass "[ns_config ns/db/pool/$default_pool User]/[ns_config ns/db/pool/$default_pool Password]"
    # Sometimes a DataSource is specified, esp in a chroot env. -bmq
    set datasource [ns_config ns/db/pool/$default_pool DataSource]
    if { ![empty_string_p $datasource] } {
	append user_pass "@$datasource"
    }
    # Use $ORACLE_HOME in the environment to determine where the sqlplus binary lives.
    if { [catch { return [exec "$env(ORACLE_HOME)/bin/sqlplus" $user_pass "@$path"] } error] } {
	return $error
    }
}

proc_doc apm_guess_file_type { path } {

    Guesses and returns the file type key corresponding to a particular path
    (or an empty string if none is known). <code>$path</code> should be
    relative to the package directory (e.g., <code>apm/admin-www/index.tcl<code>
    for <code>/packages/acs-core/apm/admin-www/index.tcl</code>. We use the following rules:

    <ol>
    <li>Files with extension <code>.sql</code> are considered data-model files,
    or if any path contains the substring <code>upgrade</code>, data-model upgrade
    files.
    <li>Files with extension <code>.info</code> are considered package specification files.
    <li>Files with a path component named <code>doc</code> are considered
    documentation files.
    <li>Files with extension <code>.pl</code> or <code>.sh</code> or
        which have a path component named
    <code>bin</code>, are considered shell-executable files.
    <li>Files with a path component named <code>templates</code> are considered
    template files.
    <li>Files with extension <code>.html</code> or <code>.adp</code>, in the top
    level of the package, are considered documentation files.
    <li>Files with a path component named <code>www</code> or <code>admin-www</code>
    are considered content-page files.
    <li>Files ending in <code>-procs.tcl</code> or <code>-init.tcl</code> are considered
    Tcl procedure or Tcl initialization files, respectively.
    </ol>

    Rules are applied in this order (stopping with the first match).

} {
    set components [split $path "/"]
    set extension [file extension $path]
    set type ""

    if { [string equal $extension ".sql"] } {
	if { [lsearch -glob $components "*upgrade*"] >= 0 } {
	    set type "data_model_upgrade"
	} else {
	    set type "data_model"
	}
    } elseif { [string equal $extension ".info"] } {
	set type "package_spec"
    } elseif { [lsearch $components "doc"] >= 0 } {
	set type "documentation"
    } elseif { [string equal $extension ".pl"] || \
	    [string equal $extension ".sh"] || \
	    [lsearch $components "bin"] >= 0 } {
	set type "shell"
    } elseif { [lsearch $components "templates"] >= 0 } {
	set type "template"
    } elseif { [llength $components] == 1 && \
	    ([string equal $extension ".html"] || [string equal $extension ".adp"]) } {
	# HTML or ADP file in the top level of a package - assume it's documentation.
	set type "documentation"
    } elseif { [lsearch $components "www"] >= 0 || [lsearch $components "admin-www"] >= 0 } {
	set type "content_page"
    } else {
	if { [string equal $extension ".tcl"] && \
		[regexp -- {-(procs|init)\.tcl$} [file tail $path] "" kind] } {
	    set type "tcl_$kind"
	}
    }
    return $type
}

proc_doc apm_ignore_file_p { path } {

    Return 1 if $path should, in general, be ignored for package operations.
    Currently, a file is ignored if it is a backup file or a CVS directory.

} {
    set tail [file tail $path]
    if { [apm_backup_file_p $tail] } {
	return 1
    }
    if { [string equal $tail "CVS"] } {
	return 1
    }
    return 0
}

proc_doc apm_backup_file_p { path } {

    Returns 1 if $path is a backup file, or 0 if not. We consider it a backup file if
    any of the following apply:

    <ul>
    <li>its name begins with <code>#</code>
    <li>its name is <code>bak</code>
    <li>its name begins with <code>bak</code> and one or more non-alphanumeric characters
    <li>its name ends with <code>.old</code>, <code>.bak</code>, or <code>~</code>
    </ul>

} {
    return [regexp {(\.old|\.bak|~)$|^#|^bak([^a-zA-Z]|$)} [file tail $path]]
}

proc_doc apm_load_any_changed_libraries {} {
    
    In the running interpreter, reloads files marked for reload by
    apm_mark_version_for_reload. If any watches are set, examines watched
    files to see whether they need to be reloaded as well. This is intended
    to be called only by the request processor (since it should be invoked
    before any filters or registered procedures are applied).

} {
    # Determine the current reload level in this interpreter by calling
    # apm_reload_level_in_this_interpreter. If this fails, we define the reload level to be
    # zero.
    if { [catch { set reload_level [apm_reload_level_in_this_interpreter] } error] } {
	proc apm_reload_level_in_this_interpreter {} { return 0 }
	set reload_level 0
    }

    # Check watched files, adding them to files_to_reload if they have
    # changed.
    set files_to_reload [list]
    foreach file [nsv_array names apm_reload_watch] {
	set path "[acs_root_dir]/$file"

	if { [file exists $path] && \
		(![nsv_exists apm_library_mtime $file] || \
		[file mtime $path] != [nsv_get apm_library_mtime $file]) } {
	    lappend files_to_reload $file
	    nsv_set apm_library_mtime $file [file mtime $path]
	}
    }

    # If there are any changed watched files, stick another entry on the
    # reload queue.
    if { [llength $files_to_reload] > 0 } {
	ns_log "Notice" "Watched file[ad_decode [llength $files_to_reload] 1 "" "s"] [join $files_to_reload ", "] [ad_decode [llength $files_to_reload] 1 "has" "have"] changed: reloading."
	set new_level [nsv_incr apm_properties reload_level]
	nsv_set apm_reload $new_level $files_to_reload
    }

    set changed_reload_level_p 0

    # Keep track of which files we've reloaded in this loop so we never
    # reload the same one twice.
    array set reloaded_files [list]
    while { $reload_level < [nsv_get apm_properties reload_level] } {
	incr reload_level
	set changed_reload_level_p 1
	# If there's no entry in apm_reload for that reload level, back out.
	if { ![nsv_exists apm_reload $reload_level] } {
	    incr reload_level -1
	    break
	}
	foreach file [nsv_get apm_reload $reload_level] {
	    # If we haven't yet reloaded the file in this loop, source it.
	    if { ![info exists reloaded_files($file)] } {
		if { [array size reloaded_files] == 0 } {
		    # Perform this ns_log only during the first iteration of this loop.
		    ns_log "Notice" "Reloading *-procs.tcl files in this interpreter..."
		}
		ns_log "Notice" "Reloading $file..."
		apm_source "[acs_root_dir]/$file"
		set reloaded_files($file) 1
	    }
	}
    }

    # We changed the reload level in this interpreter, so redefine the
    # apm_reload_level_in_this_interpreter proc.
    if { $changed_reload_level_p } {
	proc apm_reload_level_in_this_interpreter {} "return $reload_level"
    }

}

proc_doc apm_install_package_spec { version_id } {

    Writes the XML-formatted specification for a package to disk,
    marking it in the database as the only installed version of the package.
    Creates the package directory if it doesn't already exist. Overwrites
    any existing specification file; or if none exists yet, creates
    $package_key/$package_key.info and adds this new file to apm_version_files
    in the database.

} {
    set spec [apm_generate_package_spec $version_id]

    db_1row package_version_info_select {
	select package_key, version_id, package_id
	from apm_package_version_info 
	where version_id = :version_id
    }

    set root [acs_package_root_dir $package_key]
    if { ![file exists $root] } {
	file mkdir $root
	file attributes $root -permissions [ad_parameter "InfoFilePermissionsMode" "apm" 0755]
    }

    db_transaction {

	# Make sure we have a .info file set up in the data model.
	if { [db_0or1row package_spec_path_select {
            select path
            from apm_package_files
            where version_id = :version_id
            and file_type = 'package_spec'
        }] } {
	    # The .info file was already there. The path to is is now in $path.
	} else {
	    # Nothing there! We need to create add a .info file.
	    set path "$package_key.info"
	    db_dml apm_info_file_add {
                insert into apm_package_files(file_id, version_id, path, file_type)
                values(apm_package_file_id_seq.nextval, :version_id, :path, 'package_spec')
            }
	}

	set path "$root/$package_key.info"
	set file [open $path "w"]
	puts -nonewline $file $spec
	close $file

	# Mark $version_id as the only installed version of the package.
	db_dml version_mark_installed {
            update apm_package_versions
            set    installed_p = decode(version_id, :version_id, 't', 'f')
            where  package_id = :package_id
        }
    }
}

proc_doc apm_generate_package_spec { version_id } {

    Generates an XML-formatted specification for a version of a package.

} {
    db_1row package_version_select {
        select p.package_key, p.package_url, v.*
        from   apm_packages p, apm_package_versions v
        where  v.version_id = :version_id
        and    v.package_id = p.package_id
    }

    append spec "<?xml version=\"1.0\"?>
<!-- Generated by the ArsDigita Package Manager -->

<package key=\"[ad_quotehtml $package_key]\" url=\"[ad_quotehtml $package_url]\">
    <version name=\"$version_name\" url=\"[ad_quotehtml $version_url]\">
        <package-name>[ad_quotehtml $package_name]</package-name>
"
    db_foreach owner_info {
        select owner_url, owner_name
        from   apm_package_owners
        where  version_id = :version_id
        order by sort_key
    } {
        append spec "        <owner"
        if { ![empty_string_p $owner_url] } {
    	append spec " url=\"[ad_quotehtml $owner_url]\""
        }
        append spec ">[ad_quotehtml $owner_name]</owner>\n"
    }
    
    if { ![empty_string_p $summary] } {
        append spec "        <summary>[ad_quotehtml $summary]</summary>\n"
    }
    if { ![empty_string_p $release_date] } {
        append spec "        <release-date>[ad_quotehtml $release_date]</release-date>\n"
    }
    if { ![empty_string_p $vendor] || ![empty_string_p $vendor_url] } {
        append spec "        <vendor"
        if { ![empty_string_p $vendor_url] } {
    	append spec " url=\"[ad_quotehtml $vendor_url]\""
        }
        append spec ">[ad_quotehtml $vendor]</vendor>\n"
    }
    if { ![empty_string_p $description] } {
        append spec "        <description"
        if { ![empty_string_p $description_format] } {
	    append spec " format=\"[ad_quotehtml $description_format]\""
        }
        append spec ">[ad_quotehtml $description]</description>\n"
    }
    if { ![empty_string_p $distribution] } {
        append spec "        <distribution>[ad_quotehtml $distribution]</distribution>\n"
    }
    if { ![empty_string_p $package_group] } {
        append spec "        <group>[ad_quotehtml $package_group]</group>\n"
    }
    append spec "\n"
    
    db_foreach dependency_info {
        select dependency_type, service_url, service_version
        from   apm_package_dependencies
        where  version_id = :version_id
        order by dependency_type, service_url
    } {
        append spec "        <$dependency_type url=\"[ad_quotehtml $service_url]\" version=\"[ad_quotehtml $service_version]\"/>\n"
    } else {
        append spec "        <!-- No dependency information -->\n"
    }

    db_foreach version_url {
        select version_url
        from   apm_package_includes
        where  version_id = :version_id
        order by version_url
    } {
	append spec "        <include url=\"[ad_quotehtml $version_url]\"/>\n"
    } else {
	append spec "        <!-- No included packages -->\n"
    }

    append spec "\n        <files>\n"
    
    db_foreach version_path "select path, file_type from apm_package_files where version_id = :version_id order by path" {
        append spec "            <file"
        if { ![empty_string_p $file_type] } {
    	append spec " type=\"$file_type\""
        }
        append spec " path=\"[ad_quotehtml $path]\"/>\n"
    } else {
        append spec "            <!-- No files -->\n"
    }
    
    append spec "        </files>
    </version>
</package>
"
    return $spec
}

proc_doc apm_fetch_cached_vc_status { path } {

    Returns the CVS status of a file, caching it based on mtime if
    it exists and is up-to-date. The path must be relative to the
    ACS root.

} {
    # If the file doesn't exist, just do a plain old CVS status and
    # return the result - although the file doesn't exist in the
    # working copy, it can still be under CVS control!
    if { ![file exists "[acs_root_dir]/$path"] } {
	return [vc_fetch_status "[acs_root_dir]/$path"]
    }

    # If we've examined this file before, check to see if we can
    # return a cached status.
    if { [nsv_exists apm_vc_status $path] } {
	set vc_status_info [nsv_get apm_vc_status $path]
	# If the mtime hasn't changed, return the cached status.
	if { [lindex $vc_status_info 0] == [file mtime "[acs_root_dir]/$path"] } {
	    return [lindex $vc_status_info 1]
	}

	# Whoops, mtime has changed! Kill the cache entry.
	nsv_unset apm_vc_status $path
    }

    # Obtain the status. If up-to-date, cache it; if not, don't
    # (since it could easily be made up-to-date without the mtime
    # changing, i.e., checked in but not keyword-substituted).
    set status [vc_fetch_status "[acs_root_dir/$path"]
    if { [regexp "Up-to-date" $status] } {
	set mtime [file mtime "[acs_root_dir]/$path"]
	nsv_set apm_vc_status $path [list $mtime $status]
    }
    return $status
}

proc_doc apm_enable_version { version_id } {

    Enables a version of a package (disabling any other version of the package).

} {
    db_dml package_version_enable {
        update apm_package_versions
        set enabled_p = decode(version_id, :version_id, 't', 'f')
        where package_id = (
            select package_id from apm_package_versions where version_id = :version_id
        )
    }
}

proc_doc apm_disable_version { version_id } {

    Disables a version of a package.

} {
    db_dml package_version_disable "update apm_package_versions set enabled_p = 'f' where version_id = :version_id"
}

proc_doc apm_extract_tarball { version_id dir } {

    Extracts a distribution tarball into a particular directory,
    overwriting any existing files.

} {
    set apm_file [ns_tmpnam]

    db_blob_get_file distribution_tar_ball_select "select distribution_tarball from apm_package_versions where version_id = :version_id" $apm_file

    file mkdir $dir
    # cd, gunzip, and untar all in the same subprocess (to avoid having to
    # chdir first).
    exec sh -c "cd $dir ; [ad_parameter GzipExecutableDirectory "" /usr/local/bin]/gunzip -c $apm_file | tar xf -"
    file delete $apm_file
}

proc_doc apm_package_version_release_tag { package_key version_name } {

    Returns a CVS release tag for a particular package key and version name.

} {
    regsub -all {\.} [string toupper "$package_key-$version_name"] "-" release_tag
    return $release_tag
}

#####
#
# The following APIs are for the configuration manager (not stable as of this release).
#
#####

proc_doc apm_load_one_parameter {element_id} {Loads the values of one parameter into an nsv variable} {

    db_1row parameter_module_select {
	select module_key, parameter_key, default_value 
	from ad_parameter_elements
	where element_id = :element_id
    }
  
    ns_mutex lock [nsv_get $module_key lock]
    nsv_set $module_key $parameter_key [list]

    db_foreach parameter_values {
	select value from ad_parameter_values 
	where element_id = :element_id
    } {

	nsv_append $module_key $parameter_key $value

    } else {

	nsv_append $module_key_$parameter_key $default_value

    }

    db_release_unused_handles
    ns_mutex unlock [nsv_get $module_key lock]
}

proc_doc apm_load_configuration {} {Reads configuration parameters from the database and loads them into an nsv array} {

     db_foreach parameter_elements "select element_id, module_key from ad_parameter_elements" {
	 if [apm_first_time_loading_p] {
	     nsv_set $module_key lock [ns_mutex create]
	 }

	 apm_load_one_parameter $element_id
    }

    db_release_unused_handles
}

proc_doc apm_set_parameter {element_id value} {Sets the value of a specified parameter to the provided value.  For multi-valued parameters the new parameter is appended to the list of values.  For all others, it replaces any current value.} {

    db_1row parameter_select "select multiple_values_p, module_key, parameter_key from ad_parameter_elements where element_id = :element_id"

    db_release_unused_handles

    if { $multiple_values_p == "t" } {
	nsv_lappend $module_key $parameter_key $value
    } else {
	nsv_set $module_key $parameter_key [list $value]
    }
}

ad_proc apm_package_enabled_p { {} package_key } { 
     Determines whether a package is enabled in the currently
     running server (i.e., was enabled at server startup). 
} {
     return [nsv_exists apm_enabled_package $package_key]
}
