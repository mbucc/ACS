ad_page_contract {
    Disables a version of a package.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 17 April 2000
    @cvs-id version-disable.tcl,v 1.1.8.2 2000/07/21 03:55:45 ron Exp
} {
    version_id:integer
}

apm_disable_version $version_id

ns_returnredirect "version-view.tcl?version_id=$version_id"
