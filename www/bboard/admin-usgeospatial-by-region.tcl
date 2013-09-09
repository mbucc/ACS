# /www/bboard/admin-usgeospatial-by-region.tcl
ad_page_contract {
    Displays the regions in the geospatial bboard system

    @param topic the name of the bboard topic
    
    @cvs-id admin-usgeospatial-by-region.tcl,v 3.2.2.3 2000/09/22 01:36:46 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------

bboard_get_topic_info

append page_content "
[bboard_header "Pick a Region"]

<h2>Pick a region</h2>

for the $topic forum in <a href=\"index\">Discussion Forums</a> section of
<a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>
"

set region_text "<ul>\n"
# Construct the string to display at the bottom for "Ten Geographic Regions"
# as "region_text".
# Also set the region descriptions as region{n}_desc.

# We do this up here instead of writing everything out immediately so we only
# have to go to the database once for this information.

set last_region ""

db_foreach bboard_regions "
select epa_region, usps_abbrev, description 
from   bboard_epa_regions
order by epa_region, usps_abbrev" {

    if { $epa_region != $last_region } {
        if { ![empty_string_p $last_region] } {
            append region_text ")\n"
        }
	set last_region $epa_region
        set region${epa_region}_desc $description
        set region${epa_region}_url "usgeospatial-2.tcl?[export_url_vars topic epa_region]"
	append region_text "<li><a href=\"usgeospatial-2?[export_url_vars topic epa_region]\">Region $epa_region</a>: <b>$description</b> ("
    }
    append region_text "$usps_abbrev "
}
append region_text "</ul>"

ppend page_content "
<h3><a name=regions>Ten Geographic Regions</a></h3>
$region_text

[bboard_footer]
"

doc_return  200 text/html $page_content

