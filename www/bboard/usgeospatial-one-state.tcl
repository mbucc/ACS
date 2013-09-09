# /www/bboard/usgeospatial-one-state.tcl
ad_page_contract {
    Display messages for one topic/state

    @param topic the name of the bboard topic
    @param usps_abbrev the postal abbreviation of the state

    @cvs-id usgeospatial-one-state.tcl,v 3.2.2.6 2000/09/22 01:36:57 kevin Exp
} {
    topic:notnull
    usps_abbrev:notnull
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

db_1row state_name "
select state_name, epa_region from bboard_epa_regions 
where usps_abbrev = :usps_abbrev"

set menubar_items [list]

if { $users_can_initiate_threads_p != "f" } {
    lappend menubar_items "<a href=\"usgeospatial-post-new-2?[export_url_vars topic epa_region usps_abbrev]\">Start a New Thread</a>"
}

# Ulla designed this in, but philg took it out
# lappend menubar_items "<a href=\"usgeospatial?[export_url_vars topic topic_id]\">Top of Forum</a>"

if { $policy_statement != "" } {
    lappend menubar_items "<a href=\"policy?[export_url_vars topic topic_id]\">About</a>"
} 

if { [bboard_pls_blade_installed_p] } {
    lappend menubar_items "<a href=\"usgeospatial-search-form?[export_url_vars topic topic_id]\">Search</a>"
} 

lappend menubar_items "<a href=\"help?[export_url_vars topic topic_id]\">Help</a>"

# lappend menubar_items "<a href=\"/env-releases/state?usps_abbrev=$usps_abbrev\">View State Environmental Release Report</a>"

set top_menubar [join $menubar_items " | "]

append page_content "
[bboard_header "$topic : $state_name"]

<h2>$state_name</h2>

"

if { ![info exists blather] || $blather == "" } {
    # produce a stock header
    append page_content "part of the <a href=\"usgeospatial-2?[export_url_vars topic epa_region]\">$topic (Region $epa_region) forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>"
} else {
    append page_content $blather
}

append page_content "

<hr>

\[$top_menubar\]

<br>
<br>

"

# this is not currently used, moderation should be turned on with certain
# moderation_policies in case we add more

set approved_clause ""
set last_county_name ""
set county_counter "A"
set last_new_subject ""

db_foreach messages_for_one_state "
select msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       users.user_id as poster_id, 
       bboard.fips_county_code, 
       counties.fips_county_name as county_name
from   bboard, 
       users, 
       counties
where  bboard.user_id = users.user_id 
and    bboard.fips_county_code = counties.fips_county_code(+)
and    topic_id = :topic_id $approved_clause
and    bboard.usps_abbrev = :usps_abbrev
order by state_name, county_name, sort_key" {

    if { $county_name != $last_county_name } {
	if ![empty_string_p $county_name] {
	    set county_link "<a href=\"usgeospatial-one-county?[export_url_vars topic fips_county_code]\">$county_name COUNTY</a>"
	    append page_content "[usgeo_n_spaces 7]${county_counter}. $county_link<br>\n"
	} else {
	    append page_content "[usgeo_n_spaces 7]${county_counter}. STATE-WIDE<br>\n"
	}
	set last_county_name $county_name
	set county_counter [lindex [increment_char_digit $county_counter] 0]
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
    append page_content "$indentation<a href=\"usgeospatial-fetch-msg?msg_id=[ns_urlencode $thread_start_msg_id]\">$display_string</a><br>\n"
}

append page_content "

<p>

This forum is maintained by $maintainer_name (<a href=\"mailto:$maintainer_email\">$maintainer_email</a>).  

<p>

If you want to follow this discussion by email, 
<a href=\"add-alert?[export_url_vars topic topic_id]\">
click here to add an alert</a>.

[bboard_footer]
"

doc_return  200 text/html $page_content