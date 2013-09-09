ad_page_contract { 
    Generates a package spec.

    @param version_id The package to be processed.
    @param write_p Set to 1 if you want the specification file written to disk.
    @author Jon Salz [jsalz@arsdigita.com]
    @date 9 May 2000
    @cvs-id version-generate-info.tcl,v 1.1.8.3 2000/07/21 03:55:46 ron Exp
} {
    {version_id:integer}
    {write_p 0}
}

if { $write_p } {
    if { [catch { apm_install_package_spec $version_id } error] } {
	ad_return_error "Error" "Unable to create the specification file:
<blockquote><pre>$error</pre></blockquote>
"
        return
    }

    ad_returnredirect "version-view.tcl?version_id=$version_id"
} else {
    doc_set_mime_type text/plain
    doc_body_append [apm_generate_package_spec $version_id]
}
