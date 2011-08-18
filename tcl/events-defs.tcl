# we put this in here because some people might not configure their 
# AOLservers properly.  If this doesn't show up in the error log, 
# probably private Tcl and modules are configured right

#ns_log Notice "events defs.tcl being sourced"

# Check for the user cookie, redirect if not found.
proc events_security_checks {args why} {
    uplevel {
	set user_id [ad_verify_and_get_user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	    return filter_return
	} 
	return filter_ok
    }
}

# return the GID of the events admin group
proc events_admin_group {db} {
    return [ad_administration_group_id $db "events" ""]
}

# return id of the default admin user (system admin)
proc default_events_admin_user {db} {
    set admins [database_to_tcl_list $db "select ugm.user_id
    from user_group_map ugm
    where ugm.group_id = [events_admin_group $db]"]
    return [lindex $admins 0]
}

# returns 1 if current user is in admin group for events module
proc events_user_admin_p {db} {
    set user_id [ad_verify_and_get_user_id]
    return [ad_administration_group_member $db events "" $user_id]
}

# Checks if user is logged in, AND is a member of the events admin group
proc events_security_checks_admin {args why} {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id == 0} {
	ad_returnredirect "/register/index.tcl?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    } 

    set db [ns_db gethandle subquery]
    
    if {![events_user_admin_p $db]} {
	ns_db releasehandle $db
	ad_return_error "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
	
    ns_db releasehandle $db

    return filter_ok
}

#register security filters
ns_share -init {set ad_events_filters_installed 0} ad_events_filters_installed

if {!$ad_events_filters_installed} {
    set ad_events_filters_installed 1
    ad_register_filter preauth HEAD /events/admin/* events_security_checks_admin
    ad_register_filter preauth HEAD /events/*       events_security_checks
    ad_register_filter preauth GET  /events/admin/* events_security_checks_admin
    ad_register_filter preauth GET  /events/*       events_security_checks
    ad_register_filter preauth POST /events/admin/* events_security_checks_admin
    ad_register_filter preauth POST /events/*       events_security_checks
}

proc_doc events_event_name {db event_id} "Returns the event's name.  Returns an empty string if event_id is not valid" {
    return [database_to_tcl_string_or_null $db "
    select short_name
    from events_events e, events_activities a
    where e.event_id = $event_id
    and a.activity_id = e.activity_id"]
}


proc_doc events_pretty_event {db event_id} "Returns a pretty description of the event.  Returns an empty string if event_id is not valid" {
    set selection [ns_db 0or1row $db "
    select short_name, venue_id, start_time, end_time
    from events_events e, events_activities a
    where e.event_id = $event_id
    and a.activity_id = e.activity_id"]

    if {[empty_string_p $selection]} {
	return ""
    }

    set_variables_after_query
    return "$short_name in 
    [events_pretty_venue $db $venue_id]
    from [util_AnsiDatetoPrettyDate $start_time] to
    [util_AnsiDatetoPrettyDate $end_time]"
}

proc_doc events_group_add_user {db event_id user_id} "Add's user_id to the user group of event_id's event.  Returns 1 if successful, else returns 0." {
    set group_id [database_to_tcl_string_or_null $db "select group_id
    from events_events
    where event_id = $event_id" 0]
    if {$group_id == 0} {
	return 0
    }

    set return_id 1

    if [catch {set return_id [ad_user_group_user_add $db $user_id "member" $group_id]} errmsg] {
	set return_id 0
    }

    return return_id
}

proc_doc events_group_create {db name date location} "Given an event's name, date, and location, creates a user_group for that event and returns the new group's group_id.  Returns 0 if an error occurs" {

    set group_name "$name on $date at $location"
    return [ad_user_group_add $db "event" $group_name "t" "t"]
}

proc events_pretty_location {db city usps_abbrev iso} {
    if { $iso == "us" } {
	set location "$city, $usps_abbrev "
    } else {
	set location "$city, [database_to_tcl_string $db "select country_name from country_codes where iso = '$iso'"]"
    }
}   

proc_doc events_pretty_venue {db venue_id} "returns a pretty location based upon a venue_id.  If the venue_id is invalid, returns an empty string" {
    set selection [ns_db 0or1row $db "select
    city, usps_abbrev, iso
    from events_venues
    where venue_id = $venue_id"]
    
    if {[empty_string_p $selection]} {
	return ""
    }

    set_variables_after_query

    return [events_pretty_location $db $city $usps_abbrev $iso]
}

proc_doc events_pretty_venue_name {db venue_id} "returns a pretty location and that location's name based upon a venue_id.  If the venue_id is invalid, returns an empty string" {
    set selection [ns_db 0or1row $db "select
    city, usps_abbrev, iso, venue_name
    from events_venues
    where venue_id = $venue_id"]
    
    if {[empty_string_p $selection]} {
	return ""
    }

    set_variables_after_query
    
    set pretty_location "$venue_name: "
    return [append pretty_location [events_pretty_location $db $city $usps_abbrev $iso]]
}
    
proc events_venues_widget {db db_sub {default "" } {size_subtag "size=4"}} {
    set selection [ns_db select $db "select venue_id, venue_name, city, 
    usps_abbrev, iso from events_venues order by city"]
    
    set return_str "<select name=venue_id $size_subtag>"
    if {[empty_string_p $default]} {
	set options_counter 0
    } else {
	set options_counter 1
    }
    
    while {[ns_db getrow $db $selection]} {  
	set_variables_after_query
	if {$options_counter == 0 || $default == $venue_id} {
	    append return_str "<option selected value=$venue_id>[events_pretty_location $db_sub $city $usps_abbrev $iso]: $venue_name"
	} else {
	    append return_str "<option value=$venue_id>[events_pretty_location $db_sub $city $usps_abbrev $iso]: $venue_name"
	}
	incr options_counter
    }

    #if there weren't any venues, don't return a widget
    if {$options_counter > 0 } {
	append return_str "</select>"
    } else {
	set return_str ""
    }
    return $return_str
}

proc events_member_groups_widget {db user_id {group_id ""}} {
    set return_str "<select name=group_id>"
    if {[empty_string_p $group_id]} {
	append return_str "<option SELECTED value=\"\">"
    } else {
	append return_str "<option value=\"\">"
    }

    set selection [ns_db select $db "select 
    distinct g.group_id as a_group_id, 
    g.group_name
    from user_groups g, user_group_map ugm
    where g.group_id = ugm.group_id
    and ugm.user_id = $user_id"]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query

	if {$a_group_id == $group_id} {
	    	append return_str "<option selected value=$a_group_id>$group_name"
	} else {
	    append return_str "<option value=$a_group_id>$group_name"
	}
    }
    append return_str "</select>"
    return $return_str
}

proc events_verify_admin {db user_id} {    
    set admin_p [expr [ad_permission_p $db "events" "" "" $user_id] || [ad_permission_p $db "events" "activities" $user_id]]
    if { $admin_p == 0} {
	ReturnHeaders
	ns_write "[ad_header "Unauthorized Access"]
	<h1>Unauthorized Access</h1>
	<hr>
	You do not have permission to access this page.
	[ad_footer]"
	#jump out of two levels
	return -code return
    }
}
proc events_oracle_price_format {} {
    return "999,999.99"
}
proc events_write_order_summary {} {
    # this assumes that the calling environment contains Tcl vars
    # for all the columns of the events_orders table plus short_name
    uplevel {
	if [info exists city] {
	    # most lecturers are most interested in which city 
	    set best_description "$city, $usps_abbrev ($short_name)"
	} else {
	    set best_description $short_name
	}
	ns_write "<a href=\"reg-view.tcl?reg_id=$reg_id\">$reg_id</a> : $best_description from $first_names $last_name\n"
	if [info exists confirmed_date] {
	    ns_write " on [util_IllustraDatetoPrettyDate $confirmed_date] "
	}
	if {$reg_state == "canceled"} {
	    ns_write "<font color=red>($reg_state)</font>\n"
	} else {
	    ns_write "($reg_state)\n"
	}
    }
}

proc events_currency_widget {{default ""}} {
    set widget_value "<select name=currency>\n"
    set iso_list [list AUD CAD EUR NZD GBP USD]
    foreach iso $iso_list {
	if { $default == $iso } {
	    append widget_value "<option value=\"$iso\" SELECTED>$iso</option>\n" 
	} else {	    
	    append widget_value "<option value=\"$iso\">$iso</option>\n"
	}
    }
    append widget_value "</select>\n"
    return $widget_value
}

proc_doc events_makesecure {} "If the current page isn't secure, will ns_redirect the user to the https version of the page. If the nsssl module isn't installed, the function will return 0 but not try to redirect. Uses the nssssl/Port entry in the .ini file to guess the secure port (or will leave it off if the port isn't specified (in which case we're using the default https port))." {

    if {[ns_conn driver] == "nsssl"} {
        # we don't need to do anything
        return 1
    } else {
        if [empty_string_p [ns_config ns/server/[ns_info server]/modules nsssl]] {
            # we don't have ssl installed. Give up.
            return 0
        } else {
            set secure_url "https://[ns_config ns/server/[ns_info server]/module/nssock Hostname]"
            set secure_port [ns_config ns/server/[ns_info server]/module/nsssl Port]
            if ![empty_string_p $secure_port] {
                append secure_url ":$secure_port"
            }
            append secure_url [ns_conn url]
            set query_string [ns_conn query]
            if ![empty_string_p $query_string] {
                append secure_url "?$query_string"
            }
            ad_returnredirect $secure_url
            return -code return
        }
    }
}

proc_doc events_securelink {new_page} "Allows you to create a relative link to a secure page" {

    if {[ns_conn driver] == "nsssl"} {
        return $new_page
    } else {
        set new_url "https://[ns_config ns/server/[ns_info server]/module/nsssl Hostname]"

        set port [ns_config ns/server/[ns_info server]/module/nsssl Port]
        if {![empty_string_p $port] && ($port != 443)} {
           append new_url ":$port"
        }

        if [string match /* $new_page] {
           append new_url $new_page
        } else {
           set current_url [ns_conn url]
           regexp {^(.*)/} $current_url match new_url_dir
           append new_url "$new_url_dir/$new_page"
        }
        return $new_url
    }
}

proc_doc events_insecurelink {new_page} "Allows you to create a relative link from a secure page to an insecure page" {

    if {[ns_conn driver] != "nsssl"} {
        return $new_page
    } else {
        set new_url "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]"

        set port [ns_config ns/server/[ns_info server]/module/nssock Port]
        if {![empty_string_p $port] && ($port != 80)} {
           append new_url ":$port"
        }

        if [string match /* $new_page] {
           append new_url $new_page
        } else {
           set current_url [ns_conn url]
           regexp {^(.*)/} $current_url match new_url_dir
           append new_url "$new_url_dir/$new_page"
        }
        return $new_url
    }
}

proc_doc events_makeinsecure {} "If the user requests a secure page, they'll be redirected to the insecure version of that page. This is probably not the function you want because Netscape throws up a \"the document you requested was supposed to be secure\" window. events_insecureurl is probably a better choice" { 
    if {[ns_conn driver] != "nsssl"} {
        return
    } else {
        set url "http://[ns_config ns/server/[ns_info server]/module/nssock Hostname]"
        set port [ns_config ns/server/[ns_info server]/module/nssock Port]
        if ![empty_string_p $port] {
            append url ":$port"
        }
        append url [ns_conn url]
        set query_string [ns_conn query]
        if ![empty_string_p $query_string] {
            append secure_url "?$query_string"
        }
        ad_returnredirect $url
        return -code return
    }
}

proc_doc valid_int_p {number} "Checks if a number is a valid integer" {
    if {[regexp {[^0-9]} $number match]} {
	return 0
    } else {
	return 1
    }
}

proc events_helper_table_name {event_id} {
    set table_name "event_"
    return [append table_name $event_id "_info"]
}

