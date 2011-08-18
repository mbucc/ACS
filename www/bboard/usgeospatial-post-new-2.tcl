# $Id: usgeospatial-post-new-2.tcl,v 3.0 2000/02/06 03:35:00 ron Exp $
set_the_usual_form_variables

# topic, epa_region, usps_abbrev

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


set full_state_name [database_to_tcl_string $db "select state_name from rel_search_st where state = '$QQusps_abbrev'"]

ReturnHeaders

ns_write "[bboard_header "Pick a county in $full_state_name"]

<h2>Pick a County</h2>

so that you can add a thread to 
<a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>.

<hr>

<ul>

"

set selection [ns_db select $db "
SELECT
     FIPS_COUNTY_CODE,
     FIPS_COUNTY_NAME,
     STATE
FROM
    REL_SEARCH_CO
WHERE
    STATE = '$usps_abbrev'
ORDER BY
    FIPS_COUNTY_NAME"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]\">$fips_county_name</a>\n"
}

ns_write "

<p>

<li><a href=\"usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev]\">this posting is about $full_state_name but not about a particular county</a>\n


</ul>


[bboard_footer]
"
