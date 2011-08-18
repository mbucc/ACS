# glassroom-defs.tcl
#
# jsc@arsdigita.com, July 1999
#
# $Id: glassroom-defs.tcl,v 3.0.4.1 2000/03/17 18:26:33 aure Exp $

proc glassroom_system_owner { } {
    return [ad_parameter SystemOwner glassroom [ad_system_owner]]
}


proc glassroom_footer { } {
    return [ad_footer [glassroom_system_owner]]
}



# utility for host-add-2.adp and host-edit-2.adp to do some arg checking
# (There doesn't seem to be a way to return a value from an ns_adp_included
# file)
#
# if there's a problem an ad_return_complaint is done, and this will return 
# zero, in that case, the caller should not do anything else and should just
# exit

proc glassroom_check_host_args { hostname ip_address further_docs_url } {
    set exception_count 0
    set exception_text ""
    
    # hostname should be fully-qualified
    
    if { ![info exists hostname] || [llength [split $hostname "."]] < 2 } {
	incr exception_count
	append exception_text "<li> The hostname doesn't look like it's fully qualified (e.g. samoyed.arsdigita.com)\n"
    }
    
    
    # ip address should be #.#.#.# at least.
    
    if { ![info exists ip_address] || [llength [split $ip_address "."]] < 4 } {
	incr exception_count
	append exception_text "<li> The IP address needs to be digits seperated by periods. (e.g. 192.168.100.42)\n"
    } elseif { [regexp "\[^0-9.\]" $ip_address] } {
	incr exception_count
	append exception_text "<li> The IP address must be composed of only digits and periods (e.g. 192.168.100.42)\n"
    }
    
    # url should be valid.  it's optional
    
    if { [info exists $further_docs_url] } {
	if ![philg_url_valid_p $further_docs_url] {
	    incr exception_count
	    append exception_text "<li> The Other Documentation URL doesn't look like a valid URL (e.g. http://www.hamsterdance.com)\n"
	}
    }
    
    set happy_p 1
    
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	set happy_p 0
    }

    return $happy_p
    
} ;# glassroom_check_host_args



# need at least a module name.  anything else to be checked???

proc glassroom_check_module_args { module_name who_installed_it who_owns_it source current_version } {

    set exception_count 0
    set exception_text ""

    if { [empty_string_p $module_name] } {
	incr exception_count
	append exception_text "<li> The Module Name needs to be non-empty"
    }

    set happy_p 1
    
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	set happy_p 0
    }

    return $happy_p

} ;# glassroom_check_module_args



# need at least a module name.  anything else to be checked???

proc glassroom_check_release_args { release_date anticipated_release_date release_name manager } {

    set exception_count 0
    set exception_text ""

    if { [empty_string_p $release_name] } {
	incr exception_count
	append exception_text "<li> The Release Name needs to be non-empty"
    }

    set happy_p 1
    
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	set happy_p 0
    }

    return $happy_p

} ;# glassroom_check_release_args



proc glassroom_check_procedure_args { procedure_name procedure_description responsible_user responsible_user_group max_time_interval importance } {

    set exception_count 0
    set exception_text ""

    # procedure_name needs to be set

    if { [empty_string_p $procedure_name] } {
	incr exception_count
	append exception_text "<li> The Procedure Name needs to be non-empty."
    }


    # responsible_user or responsible_user_group must be non-NULL

    if { [empty_string_p $responsible_user] && [empty_string_p $responsible_user_group] } {
	incr exception_count
	append exception_text "<li> You need to supply a Responsible User or a Responsible Group"
    }


    # max_time_interval must be positive number if supplied

    if { ![empty_string_p $max_time_interval] && ( [regexp {[^0-9.]} $max_time_interval] || ($max_time_interval <= 0) ) } {
	incr exception_count
	append exception_text "<li> The Maximum Time Interval must be a number greater than zero."
    }


    # importance must be a number between 1 and 10

    if { [empty_string_p $importance] || [regexp {[^0-9.]} $importance] || ($importance < 1) || ($importance > 10) } {
	incr exception_count
	append exception_text "<li> The Importance rating must be a number between 1 and 10"
    }


    set happy_p 1
    
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	set happy_p 0
    }

    return $happy_p

} ;# glassroom_check_procedure_args


proc glassroom_submit_button { button_text } {
    # this proc is a work-around for ns_adp_parse being busted in 3.0
    return "<input type=submit name=submit value=\"$button_text\">"
}

proc glassroom_form_action { action_url } {
    # this proc is a work-around for ns_adp_parse being busted in 3.0
    return "<form method=POST action=\"$action_url\">"
}


proc glassroom_check_service_args { service_name web_service_host rdbms_host dns_primary_host dns_secondary_host disaster_host } {
    
    set exception_count 0
    set exception_text ""

    # service_name needs to be set

    if { [empty_string_p $service_name] } {
	incr exception_count
	append exception_text "<li> The Service Name needs to be non-empty."
    }


    set happy_p 1
    
    if { $exception_count > 0 } {
	ad_return_complaint $exception_count $exception_text
	set happy_p 0
    }

    return $happy_p


} ;# glassroom_check_service_args
