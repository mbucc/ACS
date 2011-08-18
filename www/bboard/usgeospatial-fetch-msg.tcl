# $Id: usgeospatial-fetch-msg.tcl,v 3.0 2000/02/06 03:34:55 ron Exp $
set_form_variables

# msg_id is the key
# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select to_char(posting_time,'Month dd, yyyy') as posting_date,bboard.*, users.user_id as poster_id,  users.first_names || ' ' || users.last_name as name, bboard.tri_id, facility, fips_county_name, rel_search_st.state_name, city
from bboard, users, rel_search_fac, rel_search_co, rel_search_st
where bboard.user_id = users.user_id
and bboard.tri_id = rel_search_fac.tri_id(+)
and bboard.fips_county_code = rel_search_co.fips_county_code(+)
and bboard.usps_abbrev = rel_search_st.state
and msg_id = '$msg_id'"]

if { $selection == "" } {
    # message was probably deleted
    ns_return 200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set_variables_after_query
set this_one_line $one_line


# now variables like $message and $topic are defined

set QQtopic [DoubleApos $topic]

if {[bboard_get_topic_info] == -1} {
    return
}

set contributed_by "-- <a href=\"contributions.tcl?user_id=$poster_id\">$name</a>, $posting_date."

if { ![empty_string_p $tri_id] && ![empty_string_p $facility] } {
    set facility_link "about <a href=\"/env-releases/facility.tcl?[export_url_vars tri_id]\">$facility</a>"
} else {
    set facility_link ""
}

if { ![empty_string_p $tri_id] && ![empty_string_p $facility] } {
    # we have a facility
    set about_text $facility
    set about_link "<a href=\"/env-releases/facility.tcl?[export_url_vars tri_id]\">$facility ($city)</a>"
} elseif { ![empty_string_p $zip_code] } {
    set about_text "Zip Code $zip_code"
    set about_link "Zip Code <a href=\"/env-releases/zip-code.tcl?[export_url_vars zip_code]\">$zip_code</a>"
} elseif { ![empty_string_p $fips_county_code] } {
    set about_text "$fips_county_name County"
    set about_link "<a href=\"/env-releases/county.tcl?[export_url_vars fips_county_code]\">$fips_county_name County</a>"
} elseif { ![empty_string_p $usps_abbrev] } {
    set about_text "$state_name"
    set about_link "<a href=\"/env-releases/state.tcl?[export_url_vars usps_abbrev]\">$state_name</a>"
}

ReturnHeaders

ns_write "[bboard_header $about_text]

<h3>Discussion</h3>

about $about_link in <a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">the $topic (Region $epa_region) forum</a>
in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>
<hr>

<h4>$one_line</h4>
<blockquote>
$message
<br><br>
$contributed_by
</blockquote>
"

set QQtopic [DoubleApos $topic]
bboard_get_topic_info

set selection [ns_db select $db "select decode(email,'$maintainer_email','f','t') as not_maintainer_p, to_char(posting_time,'Month dd, yyyy') as posting_date, bboard.*, 
users.user_id as replyer_user_id,
users.first_names || ' ' || users.last_name as name, users.email 
from bboard, users
where users.user_id = bboard.user_id
and sort_key like '$msg_id%'
and msg_id <> '$msg_id'
order by not_maintainer_p, sort_key"]


while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    set contributed_by "-- <a href=\"contributions.tcl?user_id=$replyer_user_id\">$name</a>, $posting_date"

    set this_response ""
    if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	# new subject
	append this_response "<h4>$one_line</h4>\n"
    } else {
	append this_response "<br><br>\n"
    }
    append this_response "<blockquote>
$message
<br>
<br>
$contributed_by
</blockquote>
"
    lappend responses $this_response
}

if { [info exists responses] } {
    # there were some
    ns_write "[join $responses "\n\n"]\n"
}
    

ns_write "

<br>
<br>

<center>
<form method=get action=usgeospatial-post-reply-form.tcl>
<input type=hidden name=refers_to value=\"$this_msg_id\">
<input type=submit value=\"Post a response\"</a>
</form>
</center>

&nbsp;
&nbsp;
&nbsp;

or start a new thread about

<a href=\"usgeospatial-post-new.tcl?[export_url_vars topic epa_region]\">Region $epa_region</a> :
<a href=\"usgeospatial-post-new-2.tcl?[export_url_vars topic epa_region usps_abbrev]\">$state_name</a>

"

if ![empty_string_p $fips_county_code] {
    ns_write ": <a href=\"usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]\">$fips_county_name County</a>"

}

if ![empty_string_p $facility] {
    set force_p "t"
    ns_write ": <a href=\"usgeospatial-post-new-tri.tcl?[export_url_vars topic tri_id force_p]\">$facility</a>"
}

ns_write "

[bboard_footer]
"
