# /packages/acs-core/bootstrap.tcl
#
# Code to bootstrap ACS, invoked by /tcl/0-acs-init.tcl.
#
# @creation-date 12 May 2000
# @author Jon Salz (jsalz@arsdigita.com)
# @cvs-id bootstrap.tcl,v 1.10.2.6 2000/09/05 13:11:55 bquinn Exp

# Remember the length of the error log file (so we can easily seek back to this
# point later). This is used in /www/admin/monitoring/startup-log.tcl to show
# the segment of the error log corresponding to server initialization (between
# "AOLserver/xxx starting" and "AOLserver/xxx running").
catch { nsv_set acs_properties initial_error_log_length [file size [ns_info log]] }

# Initialize proc_doc NSV arrays.
nsv_set proc_source_file . ""

# Initialize loader NSV arrays. See apm-procs.tcl for a description of
# these arrays.
nsv_array set apm_library_mtime [list]
nsv_array set apm_version_procs_loaded_p [list]
nsv_array set apm_reload_watch [list]
nsv_array set apm_package_info [list]
nsv_set apm_properties reload_level 0

###
#
# Bootstrapping code.
#
###

# Check to make sure no files listed in $root_directory/www/install/obsolete.txt
# exist.

set removed_files_path "$root_directory/www/install/obsolete.txt"
if { [file exists $removed_files_path] } {
    if { [catch {
	set file [open $removed_files_path "r"]
	while { [gets $file line] != -1 } {
	    # Trim comments.
	    regsub {\#.*} $line "" line

	    # Trim whitespace.
	    set line [string trim $line]

	    # Remove anything after the first space (since a comment might
	    # follow the file name).
	    regsub { .+$} $line "" line

	    # Trim leading slash.
	    set line [string trimleft $line "/"]

	    set removed_path "$root_directory/$line"
	    if { ![string equal $line ""] && [file exists $removed_path] } {
		ns_log "Error" "According to /www/install/obsolete.txt, the file $removed_path should not exist for this release of ACS. Please delete it."
	    }
	}
	close $file
    } error] } {
	ns_log "Error" "Unable to read the list of removed files in $removed_files_path: $error"
    }
} else {
    ns_log "Error" "The list of removed files, $removed_files_path, does not exist"
}

# Define a helper routine we can use to source files in a clear environment
# (no locals). We need this since apm_source is not yet defined.
proc bootstrap_source { __file } {
    if { [catch { source $__file }] } {
	global errorInfo
	ns_log "Error" "Error sourcing core library $__file: $errorInfo"
    }
}

# Load all the -procs file in the acs-core package, in lexicographical order.
# This is the first time each of these files is being loaded (see
# the documentation for the apm_first_time_loading_p proc).
global apm_first_time_loading_p
set apm_first_time_loading_p 1

set files [glob -nocomplain "$root_directory/packages/acs-core/*-procs.tcl"]
if { [llength $files] == 0 } {
    ns_log "Error" "Unable to locate $root_directory/packages/$package_key/*-procs.tcl. Aborting."
    return
}

foreach file [lsort $files] {
    # Clip $root_directory/packages from the beginning of the file name.
    set relative_path [string range $file \
	    [expr { [string length "$root_directory/packages"] + 1 }] end]

    ns_log "Notice" "Loading packages/$relative_path..."
    bootstrap_source $file
    nsv_set apm_library_mtime packages/$relative_path [file mtime $file]

    # Call db_release_unused_handles, only if the library defining it
    # (10-database-procs.tcl) has been sourced yet.
    if { [llength [info procs db_release_unused_handles]] != 0 } {
	db_release_unused_handles
    }
}

unset apm_first_time_loading_p

# Delete the bootstrap_source procedure, since it's no longer needed.
rename bootstrap_source ""

# In order to make sure there are database handles available, just grab one and
# release it immediately. Don't bother starting up if not.
if { [catch { set db [ns_db gethandle -timeout 15]}] || ![string compare $db ""] } {
    # Unable to grab a database handle! Uhoh.
    ns_log "Error" "Unable to allocate a database handle. Aborting."
    return
}
ns_db releasehandle $db

# Scan subdirectories in /packages for new packages which haven't yet been
# registered in the database.
apm_register_new_packages

# Make sure that some version of the acs core is marked enabled (in case
# we just scanned it in). This is necessary so that apm_load_libraries init
# (below) will initialize the core.

if { [catch { db_dml apm_package_enabled "begin apm_insure_package_enabled('acs-core'); end;" }] } {
    global errorInfo
    ns_log "Error" "Unable to enable the acs-core package - the APM data model (/packages/acs-core/apm.sql) is probably not loaded correctly. Aborting.\n$errorInfo"
    return
}
db_release_unused_handles

# Load *-procs.tcl and *-init.tcl files for enabled packages.
apm_load_libraries procs
apm_load_libraries init

if { ![nsv_exists ad_security request] } {
    # security-init.tcl has not been invoked, so it's safe to say that the
    # core has not been properly initialized and the server will probably
    # fail catastrophically.
    ns_log "Error" "The ACS core has not been initialized. Aborting."
    return
}

ns_log "Notice" "Done loading ACS."
