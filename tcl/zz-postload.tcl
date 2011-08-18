# $Id: zz-postload.tcl,v 3.2 2000/02/27 06:57:31 jsalz Exp $
# Name:        00-ad-postload.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        24 Feb 2000
# Description: Sources library files that need to be loaded after the rest.

ns_log "Notice" "Sourcing files for postload..."
foreach file {
    ad-custom.tcl.postload
} {
    ns_log Notice "postloading [ns_info tcllib]/$file"
    source "[ns_info tcllib]/$file"
}
ns_log "Notice" "Done."

