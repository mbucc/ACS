ad_library {

    Initialization stuff for the request processing pipeline.

    @creation-date 30 May 2000
    @author Jon Salz [jsalz@arsdigita.com]
    @cvs-id request-processor-init.tcl,v 1.3.2.1 2000/07/10 18:27:15 yon Exp

}

# For each SystemURLSection parameter set, add an item to the rp_system_sections
# array. (If none are set, assume "SYSTEM" as the only SystemURLSection.)
set system_url_sections [ad_parameter_all_values_as_list SystemURLSection request-processor]
if { [llength $system_url_sections] == 0 } {
    set system_url_sections [list "SYSTEM"]
}
nsv_set rp_system_sections . ""
foreach section $system_url_sections {
    nsv_set rp_system_url_sections $section 1
}

# Set up mappings in the request processor for all enabled packages, routing
# requests from URL /$package_key/ to the /packages/$package_key/www directory,
# and requests from URL /admin/$package_key/ to the /packages/$package_key/admin-www
# directory.

db_foreach request_processor "select package_key from apm_enabled_package_versions" {
    rp_register_directory_map $package_key $package_key
}
