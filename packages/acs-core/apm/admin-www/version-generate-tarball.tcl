ad_page_contract {     
    Generates a tarball for a package into its distribution_tarball field.    
    
    @param version_id The package to be processed.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-generate-tarball.tcl,v 1.1.8.4 2000/07/21 03:55:47 ron Exp
} {
    {version_id:integer}
}

apm_generate_tarball $version_id
ad_returnredirect "version-view.tcl?version_id=$version_id"
