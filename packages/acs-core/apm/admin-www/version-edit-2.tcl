ad_page_contract {
    Edit a package version
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-edit-2.tcl,v 1.3.2.5 2000/09/12 18:56:49 richardl Exp

} {
    version_id:integer
    package_name
    version_name
    version_url
    summary
    description
    description_format
    { owner_name -array }
    { owner_url -array }
    vendor
    vendor_url
    { install_p 0 }
    includes
}
db_1row  apm_version_info {
    select p.package_key, p.package_url, v.version_url old_version_url, v.version_name old_version_name
    from   apm_packages p, apm_package_versions v
    where  v.version_id = :version_id
    and    v.package_id = p.package_id
}

set version_changed_p [string compare $version_name $old_version_name]

# The user has to update the URL if he changes the name.
if { $version_changed_p && ![string compare $version_url $old_version_url] } {
    lappend exceptions "You have changed the version number but not the version URL. When creating
a package for a new version, you must select a new URL for the version."
}

foreach { name desc } {
    package_name "a name for your package"
    version_name "a version number for your package"
    version_url "a URL for this version of your package"
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

db_transaction {
    if { [catch {
	if { $version_changed_p } {
	    # Need to copy all dependencies, files, and package owners to the new version.
	    # Good thing there's a PL/SQL API for that!
	    set version_id [db_exec_plsql upgrade_plsql "
                begin
	            :1 := apm_upgrade_version($version_id, '[db_quote $version_name]', '[db_quote version_url]');
                end;
	    "]
	}
	
	# Delete and reinsert owners.
	db_dml apm_delete_owners {
	    delete from apm_package_owners where version_id = :version_id
	}
	set owner_index 1
	while { [info exists owner_name($owner_index)] && ![empty_string_p $owner_name($owner_index)] } {
	    if { ![info exists owner_url($owner_index)] } {
		set owner_url($owner_index) ""
	    }

	    db_dml apm_insert_owners {
		insert into apm_package_owners (version_id, owner_name, owner_url, sort_key)
		values
		(:version_id, :owner_name, :owner_url, :owner_index)
	    }
	    incr owner_index
	}

	# Delete and reinsert includes.
	db_dml apm_delete_includes {
	    delete from apm_package_includes where version_id = :version_id
	}
	foreach include_url [split $includes "\n\r"] {
	    if { [regexp {[^ ]} $include_url] } {
		db_dml apm_insert_includes {
                    insert into apm_package_includes(include_id, version_id, version_url)
                    values(apm_package_include_id_seq.nextval, :version_id, :include_url)
		}
	    }
	}


	db_dml apm_update_version {
	    update apm_package_versions 
		set version_url = :version_url,
		package_name = :package_name,
		summary = :summary,
		description_format = :description_format,
		description = :description,
		release_date = trunc(sysdate),
		vendor = :vendor,
		vendor_url = :vendor_url
	    where version_id = :version_id
	}	
    } error] } {
	ad_return_error "Error" "
I was unable to create your package for the following reason:

<blockquote><pre>[ns_quotehtml $error]</pre></blockquote>
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
}

ad_returnredirect "version-view.tcl?version_id=$version_id"
