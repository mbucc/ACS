ad_page_contract { 
    Enables a version of the package.
    
    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-enable.tcl,v 1.1.8.2 2000/07/21 03:55:46 ron Exp
} {
    {version_id:integer}

}

apm_enable_version $version_id

ns_returnredirect "version-view.tcl?version_id=$version_id"
