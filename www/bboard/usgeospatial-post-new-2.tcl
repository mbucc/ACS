# /www/bboard/usgeospatial-post-new-2.tcl
ad_page_contract {
    Posts a new message to the geospatial bboard system

    @param topic the name of the bboard topic
    @param epa_region the ID of the epa_region
    @param usps_abbrev the postal abbreviation

    @cvs-id usgeospatial-post-new-2.tcl,v 3.1.6.6 2000/09/22 01:36:57 kevin Exp
} {
    topic:notnull
    epa_region:notnull,integer
    usps_abbrev:notnull
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

set full_state_name [db_string state_name "
select state_name from states where usps_abbrev = :usps_abbrev"]

append page_content "
[bboard_header "Pick a county in $full_state_name"]

<h2>Pick a County</h2>

so that you can add a thread to 
<a href=\"usgeospatial-2?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>.

<hr>

<ul>

"

db_foreach county_info "
SELECT
     FIPS_COUNTY_CODE,
     FIPS_COUNTY_NAME,
     usps_abbrev
FROM
     counties
WHERE
    usps_abbrev = :usps_abbrev
ORDER BY
    FIPS_COUNTY_NAME" {

	append page_content "<li><a href=\"usgeospatial-post-new-3?[export_url_vars topic epa_region usps_abbrev fips_county_code]\">$fips_county_name</a>\n"
}

append page_content "

<p>

<li><a href=\"usgeospatial-post-new-3?[export_url_vars topic epa_region usps_abbrev]\">this posting is about $full_state_name but not about a particular county</a>\n


</ul>


[bboard_footer]
"

doc_return  200 text/html $page_content
