# we put this in here because some people might not configure their 
# AOLservers properly.  If this doesn't show up in the error log, 
# probably private Tcl and modules are configured right

#ns_log Notice "events defs.tcl being sourced"

ad_library {
    Procedures used for the events module

    @author Bryan Che (bryanche@arsdigita.com)
    @cvs_id events-defs.tcl,v 3.28.2.6 2000/08/02 01:40:58 rstorrs Exp
}


# Check for the user cookie, redirect if not found.
proc events_security_checks {args why} {
    uplevel {
	#serve the index page w/o user login
	set security_current_url [string tolower [ns_conn url]]
	if {[string compare $security_current_url "/events/index.tcl"]} {
	    return filter_ok
	} elseif {[string compare $security_current_url "/events/index"]} {
	    return filter_ok
	} elseif {[string compare $security_current_url "/events/"]} {
	    return filter_ok
	}

	set user_id [ad_verify_and_get_user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	    return filter_return
	} 
	return filter_ok
    }
}

# return the GID of the events admin group
proc events_admin_group {} {
    return [ad_administration_group_id "events" ""]
}

# return id of the default admin user (system admin)
proc default_events_admin_user {} {
    set group_id [events_admin_group]
    set admins [db_list sel_admin_id "select ugm.user_id
    from user_group_map ugm
    where ugm.group_id = :group_id"]
    return [lindex $admins 0]
}

# returns 1 if current user is in admin group for events module
proc events_user_admin_p {} {
    set user_id [ad_verify_and_get_user_id]
    return [ad_administration_group_member events "" $user_id]
}

# Checks if user is logged in, AND is a member of the events admin group
proc events_security_checks_admin {args why} {
    set user_id [ad_verify_and_get_user_id]
    if {$user_id == 0} {
	ad_returnredirect "/register/index?return_url=[ns_urlencode [ns_conn url]?[ns_conn query]]"
	return filter_return
    } 

    if {![events_user_admin_p]} {
	ad_return_forbidden "Access Denied" "Your account does not have access to this page."
	return filter_return
    }
	
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

proc_doc events_event_name {event_id} "Returns the event's name.  Returns an empty string if event_id is not valid" {
    return [db_string name "
    select short_name
    from events_events e, events_activities a
    where e.event_id = :event_id
    and a.activity_id = e.activity_id" -default [db_null] ]
}

proc_doc events_group_add_user {event_id user_id} "Add's user_id to the user group of event_id's event.  Returns 1 if successful, else returns 0." {
    set group_id [db_string sel_group_id "select group_id
    from events_events
    where event_id = :event_id" -default 0 ]
    if {$group_id == 0} {
	return 0
    }

    set return_id 1

    if [catch {set return_id [ad_user_group_user_add $user_id "member" $group_id]} errmsg] {
	set return_id 0
    }

    return return_id
}

proc_doc events_group_create {name date location} "Given an event's name, date, and location, creates a user_group for that event and returns the new group's group_id.  Returns 0 if an error occurs" {

    set group_name "$name on $date at $location"
    return [ad_user_group_add -approved_p "t" -existence_public_p "t" "event" $group_name ]
}

proc events_pretty_location {city usps_abbrev iso} {
    if { $iso == "us" } {
	set location "$city, $usps_abbrev "
    } else {
	set location "$city, [db_string sel_name "select country_name from country_codes where iso = :iso"]"
    }
}   


proc_doc events_pretty_venue {venue_id} "returns a pretty location based upon a venue_id.  If the venue_id is invalid, returns an empty string" {
    set venue_info [db_0or1row venue_info "select
    city, usps_abbrev, iso
    from events_venues
    where venue_id = :venue_id"]
    
    if {!$venue_info} {
	return ""
    }
    return [events_pretty_location $city $usps_abbrev $iso]
}

proc_doc events_pretty_venue_name {venue_id} "returns a pretty location and that location's name based upon a venue_id.  If the venue_id is invalid, returns an empty string" {
    set venue_info [db_0or1row venue_info "select
    city, usps_abbrev, iso, venue_name
    from events_venues
    where venue_id = :venue_id"]
    
    if {!$venue_info} {
	return ""
    }
    
    set pretty_location "$venue_name: "
    return [append pretty_location [events_pretty_location $city $usps_abbrev $iso]]
}

proc events_state_widget {{default ""} {size_subtag "1"} {sel_name "state"}} {
    set return_html "<select name=\"$sel_name\" size=$size_subtag>
    <option value=\"\"></option>
    "

    set default [string toupper $default]

    db_foreach states "select
    usps_abbrev, state_name
    from states
    order by state_name" {
	if {[string compare $usps_abbrev $default] == 0} {
	    append return_html "<option selected value=\"$usps_abbrev\">$state_name</option>\n"
	} else {
	    append return_html "<option value=\"$usps_abbrev\">$state_name</option>\n"
	}
    }

    append return_html "</select>"

    return $return_html
}

    
proc events_venues_widget {{default "" } {size_subtag "size=4"}} {
    set return_str "<select name=venue_id $size_subtag>"
    if {[empty_string_p $default]} {
	set options_counter 0
    } else {
	set options_counter 1
    }
    db_foreach venues "select 
    v.venue_id, v.venue_name, v.city, 
    decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location
    from events_venues v, country_codes cc
    where cc.iso = v.iso
    order by city" {
	if {$options_counter == 0 || $default == $venue_id} {
	    append return_str "<option selected value=$venue_id>$city, $big_location: $venue_name"
	} else {
	    append return_str "<option value=$venue_id>$city, $big_location: $venue_name"
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

proc_doc events_pretty_event {event_id} "Returns a pretty description of the event.  Returns an empty string if event_id is not valid" {
    if { [db_0or1row event_description_get "
    select a.short_name, e.start_time, e.end_time,
    v.city,
    decode(v.iso, 'us', v.usps_abbrev, cc.country_name) as big_location
    from events_events e, events_activities a, events_venues v,
    country_codes cc
    where e.event_id = :event_id
    and a.activity_id = e.activity_id
    and cc.iso = v.iso
    and v.venue_id = e.venue_id
    "]==0 } {
	return ""
    }

    set start [util_AnsiDatetoPrettyDate $start_time]
    set end [util_AnsiDatetoPrettyDate $end_time]

    if {$start == $end} {
	set time_str "on $start"
    } else {
	set time_str "from $start to $end"
    }

    return "$short_name in 
    $city, $big_location
    $time_str
    "
}

proc events_member_groups_widget {user_id {group_id ""}} {
    set return_str "<select name=group_id>"
    if {[empty_string_p $group_id]} {
	append return_str "<option SELECTED value=\"\">"
    } else {
	append return_str "<option value=\"\">"
    }

    db_foreach groups_list "select 
    distinct g.group_id as a_group_id, 
    g.group_name
    from user_groups g, user_group_map ugm
    where g.group_id = ugm.group_id
    and ugm.user_id = :user_id" {
	if {$a_group_id == $group_id} {
	    append return_str "<option selected value=$a_group_id>$group_name"
	} else {
	    append return_str "<option value=$a_group_id>$group_name"
	}
    }
    append return_str "</select>"
    return $return_str
}

proc events_verify_admin {user_id} {    
    set admin_p [expr [ad_permission_p "events" "" "" $user_id] || [ad_permission_p "events" "activities" $user_id]]
    if { $admin_p == 0} {
	ad_return_warning "Unauthorized Access" "
	You do not have permission to access this page."
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
    # and that the variable output_html_page is defined
    uplevel {

	set order_summary_html ""

	if [info exists city] {
	    # most lecturers are most interested in which city 
	    set best_description "$city, $usps_abbrev ($short_name)"
	} else {
	    set best_description $short_name
	}
	append order_summary_html "<a href=\"reg-view?reg_id=$reg_id\">$reg_id</a> : $best_description from $first_names $last_name\n"
	if [info exists confirmed_date] {
	    append order_summary_html " on [util_IllustraDatetoPrettyDate $confirmed_date] "
	}
	if {$reg_state == "canceled"} {
	    append order_summary_html "<font color=red>($reg_state)</font>\n"
	} else {
	    append order_summary_html "($reg_state)\n"
	}

	if {![exists_and_not_null output_html_page]} {
	    ns_write $order_summary_html
	} else {
	    append $output_html_page $order_summary_html
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
            ad_script_abort
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
        ad_script_abort
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

proc_doc events_range_bar_name {start_id display_size sql bind_vars url {url_vars ""}} "display_size is the number of registrations you'd like to view at once.  sql is a sql query that returns reg_id's ordered by reg_id asc.  bind_vars is a list of the varibles to be bound in sql.  url is the url of the page calling this procedure.  url_vars are any variables passed into url." {
    
    set return_html ""

    if {[exists_and_not_null url_vars]} {
	append url "?$url_vars&"
    } else {
	append url "?"
    }

    set first_p 1
    set count 0
    set section_start_name ""
    set section_start_id ""
    set total_count 0

    #sql is a query returning all the registrations in which
    #we're interested, ordered by last_name
    db_foreach sel_reg $sql -bind $bind_vars {
	if {$first_p == 1} {
	    set section_start_name $last_name
	    set first_p 0
	    set section_start_id $reg_id

	    if {![exists_and_not_null start_id]} {
		set start_id $reg_id
	    }
	}

	if {$count == $display_size} {

	    if {$section_start_id == $start_id} {
		append return_html "$section_start_name to $last_name |"
		set sql_start $section_start_name
		set sql_end $last_name

	    } else {
		append return_html "
		<a href=\"$url" "start_id=$section_start_id\">
		$section_start_name to $last_name</a> |
		"
	    }

	    set first_p 1
	    set count 0
		
	}

	incr count
	incr total_count
    }

    if {$count != 0} {
	if {$section_start_id == $start_id} {
	    append return_html "$section_start_name to $last_name |"
	    set sql_start $section_start_name
	    set sql_end $last_name

	} else {
	    append return_html "
	    <a href=\"$url" "start_id=$section_start_id\">
	    $section_start_name to $last_name</a> |
	    "
	}
    }

    if {$start_id < 0} {
	append return_html "all $total_count registrations"
	#display all registrations

	set reg_id_sql ""
    } else {
	append return_html "
	<a href=\"$url" "start_id=-1\">all $total_count registrations</a>"

	set reg_id_sql "and lower(last_name) >= lower('$sql_start') and lower(last_name) <= lower('$sql_end')"
    }

    #pass this into the upper calling environment
    uplevel "set reg_id_sql \"$reg_id_sql\""

    return $return_html
}
    
proc_doc events_range_bar_id {start_id display_size sql bind_vars url {url_vars ""}} "returns a bar for selecting a block of reg_id's display_size large.  start_id indicates the start of the current reg_id at which you're looking.  display_size is the number of registrations you'd like to view at once.  sql is a sql query that returns reg_id's ordered by reg_id asc.  bind_vars is a list of the varibles to be bound in sql.  url is the url of the page calling this procedure.  url_vars are any variables passed into url." {
    set original_start_id $start_id
    set return_str ""
    set found_current_range 0
    set i 0

    set url_html "?"
    if {[exists_and_not_null url_vars]} {
	append url_html $url_vars "&"
	#append url_html "&"
    } 

    set i 1
    set next_reg_id 0
    set found_current_range 0
    set first_case 1

    if {![exists_and_not_null reg_id]} {
	set reg_id 0
    }

    set total_count 0

    db_foreach sel_regs $sql -bind $bind_vars {
	if {$i == $display_size} {
	    #we've counted reg_id's to write out
	    
	    if {$original_start_id >= 0 && $original_start_id <= $reg_id && !$found_current_range} {
		#we're displaying this range, so no links
		if {$first_case} {
		    append return_str "0 to $reg_id | "
		} else {
		    append return_str "$next_reg_id to $reg_id | "
		}

		set found_current_range 1

		set end_index $reg_id

	    } else {
		#show a link for this section
		if {$first_case} {
		    set start_id 0
		    set tmp_url_html $url_html
		    append tmp_url_html "start_id=$next_reg_id"
		    append return_str "
		    <a href=\"$url$tmp_url_html\">
		    $next_reg_id to $reg_id</a> | "
		} else {
		    set start_id $i
		    set tmp_url_html $url_html
		    append tmp_url_html "start_id=$next_reg_id"
		    append return_str "
		    <a href=\"$url$tmp_url_html\">
		    $next_reg_id to $reg_id</a> | "
		}
	    }

	    #the first case is special
	    if {$first_case} {
		set first_case 0
	    }

	    set next_reg_id [expr $reg_id + 1]
	    set i 1

	} else {
	    incr i
	    
	}

	incr total_count
    }

    #append the last range if there's any left
    if {$next_reg_id <= [expr $reg_id]} {
	if {$found_current_range || $original_start_id < 0} {
	    #show a link for this section
	    set start_id $next_reg_id
	    set tmp_url_html $url_html
	    append tmp_url_html "start_id=$start_id"
	    append return_str "
	    <a href=\"$url$tmp_url_html\">
	    $next_reg_id to $reg_id</a> | "
	} else {
	    #we're displaying this range, so no links
	    append return_str "$next_reg_id to $reg_id | "
	    set found_current_range 1

	    set end_index $reg_id
	}
    }

    #show the all registrations link if start_id >=0
    if {$original_start_id >= 0 } {
	set start_id -1
	set tmp_url_html $url_html
	append tmp_url_html "start_id=$start_id"
	append return_str "<a href=\"$url$tmp_url_html\">all $total_count registrations</a>"

	set reg_id_sql "and reg_id >= $original_start_id and reg_id <= $end_index"
    } else {
	append return_str "all $total_count registrations"

	set reg_id_sql ""
    }

    #pass this into the upper calling environment
    uplevel "set reg_id_sql \"$reg_id_sql\""
	
    return $return_str
}


##################################################################
#
# interface to the ad-user-contributions-summary.tcl system

ns_share ad_user_contributions_summary_proc_list

if { ![info exists ad_user_contributions_summary_proc_list] || [util_search_list_of_lists $ad_user_contributions_summary_proc_list "Event Registrations" 0] == -1 } {
    lappend ad_user_contributions_summary_proc_list [list "Event Registrations" events_user_contributions 0]
}

proc_doc events_user_contributions {user_id purpose} "Returns list of events for which this user has registered" {

    set items ""

    db_foreach sel_contrib "
    select r.reg_id,
    to_char(r.reg_date, 'fmMonth DD, YYYY') as reg_date,
    e.event_id, e.venue_id, e.available_p,
    e.reg_deadline - sysdate as event_available,
    to_char(e.start_time, 'fmDay, fmMonth DD, YYYY') as event_start,
    a.short_name
    from events_reg_not_canceled r, events_prices p, events_events e,
    events_activities a
    where r.user_id = :user_id
    and p.price_id = r.price_id
    and e.event_id = p.event_id
    and a.activity_id = e.activity_id
    order by r.reg_date desc" {
	if { $purpose == "site_admin" } {
	    append items "<li>
	    $reg_date:
	    <a href=\"/events/admin/reg-view?[export_url_vars reg_id]\">
	    $short_name in [events_pretty_venue $venue_id] on 
	    $event_start
	    </a>\n"
	} elseif {$event_available > 0 && $available_p == "t"} {
	    #only link to the event if you can still see its order form
	    append items "
	    <li>
	    <a href=\"/events/event-info?[export_url_vars event_id]\">
	    $reg_date:
	    $short_name in [events_pretty_venue $venue_id] on 
	    $event_start</a>\n"
	} else {
	    append items "
	    <li>
	    $reg_date:
	    $short_name in [events_pretty_venue $venue_id] on 
	    $event_start\n"
	}
    }

    db_release_unused_handles

    if [empty_string_p $items] {
	return [list]
    } else {
	return [list 0 "Event Registrations" "<ul>\n\n$items\n\n</ul>"]
    }
}

# interface to the ad-user-contributions-summary.tcl system
#
##################################################################


##################################################################
#
# interface to the ad-new-stuff.tcl system

ns_share ad_new_stuff_module_list

if { ![info exists ad_new_stuff_module_list] || [lsearch -glob $ad_new_stuff_module_list "events*"] == -1 } {
    lappend ad_new_stuff_module_list [list "Events" events_new_stuff]
}

proc events_new_stuff {since_when only_from_new_users_p purpose} {
    if { $only_from_new_users_p == "t" } {
	set users_table "users_new"
    } else {
	set users_table "users"
    }

    set items "<ul>\n"
    set counter 0

    db_foreach evnt_sel_new_stuff "
    select 
    count(r.reg_id) as n_reg,
    e.event_id, e.venue_id,
    e.reg_deadline - sysdate as event_available,
    e.available_p,
    to_char(e.start_time, 'fmDay, fmMonth DD, YYYY') as event_start,
    a.short_name
    from events_reg_not_canceled r, events_prices p, events_events e,
    events_activities a, $users_table
    where r.user_id = $users_table.user_id
    and p.price_id = r.price_id
    and e.event_id = p.event_id
    and a.activity_id = e.activity_id
    and r.reg_date > :since_when
    group by e.event_id, e.reg_deadline, e.venue_id, e.available_p,
    e.start_time, a.short_name
    " {
	if { $purpose == "site_admin" } {
	    append items "
	    <li><a href=\"/events/admin/order-history-one-event?[export_url_vars event_id]\">
	    $short_name in [events_pretty_venue $venue_id] on 
	    $event_start</a> ($n_reg new registrations)\n"
	} elseif {$event_available > 0 && $available_p == "t"} {
	    #only show the link if the event is still available
	    append items "
	    <li>
	    <a href=\"/events/event-info?[export_url_vars event_id]\">
	    $short_name in [events_pretty_venue $venue_id] on 
	    $event_start</a> ($n_reg new registrations)\n"
	} else {
	    append items "
	    <li>
	    $short_name in [events_pretty_venue $venue_id] on 
	    $event_start ($n_reg new registrations)\n"
	}

	incr counter
    }

    if {$counter != 0} {
	append items "</ul>\n"
    } else {
	set items ""
    }
    db_release_unused_handles
    return $items
}


# interface to the ad-user-contributions-summary.tcl system
#
##################################################################
