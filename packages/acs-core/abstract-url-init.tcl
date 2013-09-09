ad_library {
    Provides support for abstract URL processing (see doc/abstract-url.html).
    
    @modified-by Peter Vessenes, (peterv@ybos.net) Aug-17-2000
    @author jsalz@arsdigita.com
    @date  27 Feb 2000
    @cvs-id abstract-url-init.tcl,v 1.6.2.2 2000/08/23 23:10:15 dennis Exp
}

set listings [ns_config "ns/server/[ns_info server]" "directorylisting" "none"]
if { [string equal $listings "fancy"] || [string equal $listings "simple"] } {
    nsv_set rp_directory_listing_p . 1
} else {
    nsv_set rp_directory_listing_p . 0
}

# We set up some default mappings, and allow them to be overriden by the 
# ns/server/yourservername/adp section of the configuration file. This keeps 
# backwards compatibility with the request processor, but allows ADPs to be 
# registered.

set reg_extensions(tcl)  "rp_handle_tcl_request"
set reg_extensions(adp)  "rp_handle_adp_request"
set reg_extensions(html) "rp_handle_html_request"
set reg_extensions(htm)  "rp_handle_html_request"

set config_section [ns_configsection "ns/server/[ns_info server]/adp"]
if [empty_string_p $config_section] {
    set sectionid [ns_set new "empty set for config section"]
} else {
    set sectionid $config_section
}

set maplist [list]
set counter 0

while {$counter < [ns_set size $sectionid]} {
    if {[string tolower [ns_set key $sectionid $counter]] == "map"} {
        lappend maplist [ns_set value $sectionid $counter]
    }
    incr counter
}

# We want to ignore everything but the files of the form /*.[a-zA-Z]+
# since the rp is not smart enough to register filetype handlers based
# on directories.

foreach map $maplist {
    if {[regexp {^/\*\.([A-Za-z0-9]+)$} $map match extension]} {
        set reg_extensions([string tolower $extension]) "rp_handle_adp_request"
    }
}

foreach extension [array names reg_extensions] {
    ns_log Notice "Registering $extension to $reg_extensions($extension)"

    rp_register_extension_handler $extension $reg_extensions($extension)
}

