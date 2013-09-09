ad_page_contract {
    Adds a dependency to a version of a package. 
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-dependency-remove.tcl,v 1.3.2.3 2000/07/21 03:55:45 ron Exp
} {
    {version_id:integer}
    {dependency_id:integer}
}

db_dml apm_dependency_delete {
    delete from apm_package_dependencies
    where dependency_id = :dependency_id
}

ad_returnredirect "version-dependencies.tcl?version_id=$version_id"
