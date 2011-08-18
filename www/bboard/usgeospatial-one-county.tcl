# $Id: usgeospatial-one-county.tcl,v 3.0 2000/02/06 03:34:57 ron Exp $
set_the_usual_form_variables

# topic, fips_county_code

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}



set selection [ns_db 1row $db "select fips_county_name, state as usps_abbrev from rel_search_co where fips_county_code = '$QQfips_county_code'"]
set_variables_after_query

set selection [ns_db 1row $db "select state_name, epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
set_variables_after_query

set menubar_items [list]

if { $users_can_initiate_threads_p != "f" } {
    lappend menubar_items "<a href=\"usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]\">Start a New Thread</a>"
}

# Ulla designed this in, but philg took it out
# lappend menubar_items "<a href=\"usgeospatial.tcl?[export_url_vars topic topic_id]\">Top of Forum</a>"


if { $policy_statement != "" } {
    lappend menubar_items "<a href=\"policy.tcl?[export_url_vars topic topic_id]\">About</a>"
} 


if { [bboard_pls_blade_installed_p] } {
    lappend menubar_items "<a href=\"usgeospatial-search-form.tcl?[export_url_vars topic topic_id]\">Search</a>"
} 

lappend menubar_items "<a href=\"/env-releases/county.tcl?fips_county_code=$fips_county_code\">View County Environmental Release</a>"


set top_menubar [join $menubar_items " | "]

ReturnHeaders

ns_write "[bboard_header "$topic : $fips_county_name County"]

<h2>$fips_county_name County</h2>

"

if { ![info exists blather] || $blather == "" } {
    # produce a stock header
    ns_write "part of the <a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">$topic (Region $epa_region) forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>"
} else {
    ns_write $blather
}

ns_write "

<hr>

\[$top_menubar\]

<br>
<br>

"

# this is not currently used, moderation should be turned on with certain
# moderation_policies in case we add more


set approved_clause ""

set sql "select msg_id, one_line, sort_key, email, first_names || ' ' || last_name as name, users.user_id as poster_id, facility, bboard.tri_id, city
from bboard, users, rel_search_fac
where bboard.user_id = users.user_id 
and bboard.tri_id = rel_search_fac.tri_id(+)
and topic_id = $topic_id $approved_clause
and bboard.fips_county_code = '$QQfips_county_code'
order by facility, sort_key
"


set selection [ns_db select $db $sql]

set last_facility_name ""
set facility_counter 1
set last_new_subject ""
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    if { $facility != $last_facility_name } {
	if ![empty_string_p $facility] {
	    set facility_link "<a href=\"usgeospatial-one-facility.tcl?[export_url_vars topic tri_id]\">$facility ($city)</a>"
	    ns_write "[usgeo_n_spaces 10]${facility_counter}. $facility_link<br>\n"
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
    set indentation [usgeo_n_spaces 14]
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
