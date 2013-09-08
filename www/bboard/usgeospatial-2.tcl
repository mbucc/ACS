# /www/bboard/usgeospatial-2.tcl
ad_page_contract {
    Display postings in a certain topic and region
   
    @param topic the name of the bboard topic
    @param topic_id the ID of the bboard topic
    @param epa_region the region of the country

    @cvs-id usgeospatial-2.tcl,v 3.1.6.8 2000/09/22 01:36:56 kevin Exp
} {
    {topic:trim,optional}
    {topic_id:integer,optional}
    {epa_region:integer}
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

set menubar_items [list]

if { $users_can_initiate_threads_p != "f" } {
    lappend menubar_items "<a href=\"usgeospatial-post-new?[export_url_vars topic epa_region]\">Start a New Thread</a>"
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


set top_menubar [join $menubar_items " | "]

set states_in_region [join [db_list usps_abbrevs "
select usps_abbrev
from bboard_epa_regions
where epa_region = :epa_region"] ", "]

append page_content "
[bboard_header "$topic region $epa_region"]

<h2>Region $epa_region ($states_in_region)</h2>

"

if { ![info exists blather] || $blather == "" } {
    # produce a stock header
    append page_content "part of the <a href=\"usgeospatial?[export_url_vars topic topic_id]\">$topic forum</a> in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>"
} else {
    append page_content $blather
}

append page_content "

<hr>

\[$top_menubar\]

"

# this is not currently used, moderation should be turned on with certain
# moderation_policies in case we add more


set approved_clause ""

set sql "
select msg_id, 
       one_line, 
       sort_key, 
       email, 
       first_names || ' ' || last_name as name, 
       users.user_id as poster_id, 
       bboard.usps_abbrev, 
       bboard.fips_county_code, 
       states.state_name, 
       counties.fips_county_name as county_name
from   bboard, 
       users, 
       states, 
       counties
where  bboard.user_id = users.user_id 
and    bboard.usps_abbrev = states.usps_abbrev
and    bboard.fips_county_code = counties.fips_county_code(+)
and    topic_id = :topic_id $approved_clause
and    epa_region = :epa_region
order by state_name, county_name, sort_key
"

set last_state_name ""
set state_counter 1
set last_county_name ""
set county_counter "A"
set last_new_subject ""

db_foreach messages $sql {

    if { $state_name != $last_state_name } {
	set state_link "<a href=\"usgeospatial-one-state?[export_url_vars topic_id topic usps_abbrev]\">$state_name</a>"
	append page_content "<br><br>\n${state_counter}. $state_link<br>\n"
	set last_state_name $state_name
	incr state_counter
	# have to reset the county counter
	set last_county_name ""
	set county_counter "A"
    }
    if { $county_name != $last_county_name } {
	if ![empty_string_p $county_name] {
	    append page_content "[usgeo_n_spaces 7]${county_counter}. $county_name COUNTY<br>\n"
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

