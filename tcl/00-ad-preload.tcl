# $Id: 00-ad-preload.tcl,v 3.7 2000/02/29 04:14:05 jsc Exp $
# Name:        00-ad-preload.tcl
# Author:      Jon Salz <jsalz@mit.edu>
# Date:        24 Feb 2000
# Description: Sources library files that need to be loaded before the rest.

# Necessary to determine which ad-aolserver-*.tcl.preload to source.
proc util_aolserver_2_p {} {
    if {[string index [ns_info version] 0] == "2"} {
	return 1
    } else {
	return 0
    }
}

ns_log "Notice" "Sourcing files for preload..."

if { [util_aolserver_2_p] } {
    set file_to_preload "ad-aolserver-2.tcl.preload"
    foreach file [list $file_to_preload ad-utilities.tcl.preload ad-defs.tcl.preload] {
	ns_log Notice "preloading [ns_info tcllib]/$file"
	source "[ns_info tcllib]/$file"
    }
} else {
    set file_to_preload "ad-aolserver-3.tcl.preload"
    foreach file [list ad-utilities.tcl.preload ad-defs.tcl.preload $file_to_preload] {
	ns_log Notice "preloading [ns_info tcllib]/$file"
	source "[ns_info tcllib]/$file"
    }
}

foreach file [list ad-utilities.tcl.preload ad-defs.tcl.preload $file_to_preload] {
    ns_log Notice "preloading [ns_info tcllib]/$file"
    source "[ns_info tcllib]/$file"
}
ns_log "Notice" "Done preloading."

