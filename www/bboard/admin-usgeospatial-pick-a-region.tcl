# $Id: admin-usgeospatial-pick-a-region.tcl,v 3.0 2000/02/06 03:33:28 ron Exp $
set_the_usual_form_variables

# topic required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

bboard_get_topic_info

ReturnHeaders

ns_write "[bboard_header "Pick a Region"]

<h2>Pick a region</h2>

for the $topic forum in <a href=\"index.tcl\">Discussion Forums</a> section of
<a href=\"[ad_pvt_home]\">[ad_system_name]</a>

<hr>
"

set region_text "<ul>\n"
set selection [ns_db select $db "select epa_region, usps_abbrev, description 
from bboard_epa_regions
order by epa_region, usps_abbrev"]


# Construct the string to display at the bottom for "Ten Geographic Regions"
# as "region_text".

# We do this up here instead of writing everything out immediately so we only
# have to go to the database once for this information.

set last_region ""

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $epa_region != $last_region } {
        if { ![empty_string_p $last_region] } {
            append region_text ")\n"
        }
	set last_region $epa_region
	append region_text "<li><a href=\"admin-usgeospatial-one-region.tcl?[export_url_vars topic epa_region]\">Region $epa_region</a>: <b>$description</b> ("
    }
    append region_text "$usps_abbrev "
}
append region_text "</ul>"


ns_write "
<h3><a name=regions>Ten Geographic Regions</a></h3>
$region_text
"

ns_write "[bboard_footer]"
