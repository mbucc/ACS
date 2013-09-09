ad_page_contract {
    Adds a dependency to a version of a package. 
   
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-dependency-add-2.tcl,v 1.3.2.4 2000/08/08 23:30:20 bquinn Exp
} {
    {version_id:integer}
    dependency_type:notnull
    service_url:notnull
    service_version:notnull
}


db_transaction {
    # Delete this particular dependency (in case it already exists) and re-add it.
    set dependency_type_prep "${dependency_type}s"
 
    db_dml apm_dependency_delete {
        delete from apm_package_dependencies
        where version_id = :version_id
        and   service_url = :service_url
    }
    db_dml apm_dependency_insert {
        insert into apm_package_dependencies(dependency_id, version_id, dependency_type, service_url, service_version)
        values(apm_package_dependency_id_seq.nextval, :version_id, :dependency_type_prep, :service_url, :service_version)
    }
}

db_release_unused_handles
apm_install_package_spec $version_id

ad_returnredirect "version-dependencies.tcl?version_id=$version_id"
