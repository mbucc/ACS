# $Id: usgeospatial-2.tcl,v 3.0 2000/02/06 03:34:54 ron Exp $
set_the_usual_form_variables

# topic, topic_id, epa_region

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


set menubar_items [list]

if { $users_can_initiate_threads_p != "f" } {
    lappend menubar_items "<a href=\"usgeospatial-post-new.tcl?[export_url_vars topic epa_region]\">Start a New Thread</a>"
}

# Ulla designed this in, but philg took it out
# lappend menubar_items "<a href=\"usgeospatial.tcl?[export_url_vars topic topic_id]\">Top of Forum</a>"


if { $policy_statement != "" } {
    lappend menubar_items "<a href=\"policy.tcl?[export_url_vars topic topic_id]\">About</a>"
} 


if { [bboard_pls_blade_installed_p] } {
    lappend menubar_items "<a href=\"usgeospatial-search-form.tcl?[export_url_vars topic topic_id]\">Search</a>"
} 

lappend menubar_items "<a href=\"help.tcl?[export_url_vars topic topic_id]\">Help</a>"


set top_menubar [join $menubar_items " | "]

set states_in_region [join [database_to_tcl_list $db "select usps_abbrev
from bboard_epa_regions
where epa_region = $epa_region"] ", "]

ReturnHeaders

ns_write "[bboard_header "$topic region $epa_region"]

<h2>Region $epa_region ($states_in_region)</h2>

"

if { ![info exists blather] || $blather == "" } {
    # produce a stock header
    ns_write "part of the <a href=\"usgeospatial.tcl?[export_url_vars topic topic_id]\">$topic forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>"
} else {
    ns_write $blather
}

ns_write "

<hr>

\[$top_menubar\]

"

# this is not currently used, moderation should be turned on with certain
# moderation_policies in case we add more


set approved_clause ""

set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, users.user_id as poster_id, 
bboard.usps_abbrev, bboard.fips_county_code, rel_search_st.state_name, rel_search_co.fips_county_name as county_name, facility, rel_search_fac.city
from bboard, users, rel_search_st, rel_search_co, rel_search_fac
where bboard.user_id = users.user_id 
and bboard.usps_abbrev = rel_search_st.state
and bboard.fips_county_code = rel_search_co.fips_county_code(+)
and bboard.tri_id = rel_search_fac.tri_id(+)
and topic_id = $topic_id $approved_clause
and epa_region = $epa_region
order by state_name, county_name, facility, sort_key
"


set selection [ns_db select $db $sql]

set last_state_name ""
set state_counter 1
set last_county_name ""
set county_counter "A"
set last_facility_name ""
set facility_counter 1
set last_new_subject ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $state_name != $last_state_name } {
	set state_link "<a href=\"usgeospatial-one-state.tcl?[export_url_vars topic_id topic usps_abbrev]\">$state_name</a>"
	ns_write "<br><br>\n${state_counter}. $state_link<br>\n"
	set last_state_name $state_name
	incr state_counter
	# have to reset the county counter
	set last_county_name ""
	set county_counter "A"
	set last_facility_name ""
    }
    if { $county_name != $last_county_name } {
	if ![empty_string_p $county_name] {
	    ns_write "[usgeo_n_spaces 7]${county_counter}. $county_name COUNTY<br>\n"
	} else {
	    ns_write "[usgeo_n_spaces 7]${county_counter}. STATE-WIDE<br>\n"
	}
	set last_county_name $county_name
	set county_counter [lindex [increment_char_digit $county_counter] 0]
        # reset the facility counter
        set facility_counter 1
	set last_facility_name ""
    }
    
    if { $facility != $last_facility_name } {
	if ![empty_string_p $facility] {
	    ns_write "[usgeo_n_spaces 10]${facility_counter}. $facility ($city)<br>\n"
	} else {
	    ns_write "[usgeo_n_spaces 10]${facility_counter}. COUNTY-WIDE<br>\n"
	}
        incr facility_counter
	set last_facility_name $facility
    }

    if { $one_line == "Response to $last_new_subject" } {
	set display_string "Response"
    } else {
	set last_new_subject $one_line
	set display_string $one_line
    }
    if { $subject_line_suffix == "name" && $name != "" } {
	append display_string " ($name)"
    } elseif { $subject_line_suffix == "email" && $email != "" } {
	append display_string " ($email)"
    }
    # let's set the indentation for the msg
    # right now, we indent them all the same (plus some extra for threading)
    if [empty_string_p $last_county_name] {
	set indentation [usgeo_n_spaces 14]
    } else {
	set indentation [usgeo_n_spaces 14]
    }
    # let's add indentation for threading
    append indentation [usgeo_n_spaces [expr 3 * [bboard_compute_msg_level $sort_key]]]
    if { [string first "." $sort_key] == -1 } {
	# there is no period in the sort key so this is the start of a thread
	set thread_start_msg_id $sort_key
    } else {
	# strip off the stuff before the period
	regexp {(.*)\..*} $sort_key match thread_start_msg_id
    }
    ns_write "$indentation<a href=\"usgeospatial-fetch-msg.tcl?msg_id=[ns_urlencode $thread_start_msg_id]\">$display_string</a><br>\n"
}

ns_write "

<p>

This forum is maintained by $maintainer_name (<a href=\"mailto:$maintainer_email\">$maintainer_email</a>).  

<p>

If you want to follow this discussion by email, 
<a href=\"add-alert.tcl?[export_url_vars topic topic_id]\">
click here to add an alert</a>.

[bboard_footer]
"
