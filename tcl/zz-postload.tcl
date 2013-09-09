ad_library {

    Sources library files that need to be loaded after the rest.
    
    @author Jon Salz (jsalz@mit.edu)
    @creation-date 24 Feb 2000
    @cvs-id zz-postload.tcl,v 3.4.2.1 2000/07/22 08:57:36 ron Exp
}

set tcllib [ns_info tcllib]

ns_log "Notice" "Sourcing files for postload..."
foreach file [glob -nocomplain ${tcllib}/*.tcl.postload] {
    ns_log Notice "postloading $file"
    source "$file"
}
ns_log "Notice" "Done."


