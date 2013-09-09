# /tcl/0-acs-init.tcl
#
# The very first file invoked when ACS is started up. Sources
# /packages/acs-core/bootstrap.tcl.
#
# jsalz@mit.edu, 12 May 2000
#
# 0-acs-init.tcl,v 3.2 2000/06/05 21:39:59 jsalz Exp

# Determine the ACS root directory, which is the directory right above the
# Tcl library directory [ns_info tcllib].
set root_directory [file dirname [string trimright [ns_info tcllib] "/"]]
nsv_set acs_properties root_directory $root_directory

ns_log "Notice" "Loading the ACS, rooted at $root_directory"
set bootstrap_file "$root_directory/packages/acs-core/bootstrap.tcl"
ns_log "Notice" "Sourcing $bootstrap_file"

if { [file isfile $bootstrap_file] } {
    source "$root_directory/packages/acs-core/bootstrap.tcl"
} else {
    ns_log "Error" "$bootstrap_file does not exist. Aborting the ACS load process."
}

