ad_library {
    Defines procedures that are used for initializing modules.
    @author John Lowry [lowry@arsdigita.com]
    @creation-date March 2000
    @cvs-id ad-module.tcl,v 1.2.2.1 2000/07/17 13:52:01 bquinn Exp
}

ad_proc ad_register_module { { -module_key "" -pretty_name "" -public_directory "" \
	-admin_directory "" -site_wide_admin_directory "" \
	-additional_paths ""  -description "" \
	-documentation_url "" -data_model_url "" -version "" \
	-ticket_server "" \
	-owner_email_list "" -module_type system -supports_scoping_p f \
	-cvs_host "software.arsdigita.com" \
	-bboard_server "" } } {
	This is a stub for the module manager.
} {
	return
}

