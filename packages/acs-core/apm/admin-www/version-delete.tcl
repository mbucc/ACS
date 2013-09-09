ad_page_contract {
    Deletes a version from the package manager.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-delete.tcl,v 1.4.2.3 2000/07/21 03:55:45 ron Exp
} {
    {version_id:integer}
}


db_transaction {
    
    db_1row apm_package_info_by_version_and_package_id {
        select p.package_id, p.package_key
	from apm_package_versions v, apm_packages p
	where v.version_id = :version_id
	and   p.package_id = v.package_id
    }
    # Delete the version...
    db_dml apm_delete_by_version_id {
	delete from apm_package_versions where version_id = :version_id
    }

    # ...and delete the entry in apm_packages if this was the only existing version of the
    # package.
    db_dml apm_remove_package {
	delete from apm_packages
	where package_id = :package_id
	and not exists (select 1 from apm_package_versions where package_id = :package_id)
    }
    
    if { [db_resultrows] > 0 } {
	# Try to rename the package in the packages directory, so that the next package scan
	# won't re-load the .info file.
	if { [catch { file rename [acs_package_root_dir $package_key] "[acs_package_root_dir $package_key].bak" } error] } {
	    ns_log "Notice" "Unable to rename [acs_package_root_dir $package_key]: $error"
	}
    }
}
ns_returnredirect "index"
