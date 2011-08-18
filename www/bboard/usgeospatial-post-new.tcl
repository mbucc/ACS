# $Id: usgeospatial-post-new.tcl,v 3.0 2000/02/06 03:35:09 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_the_usual_form_variables

# topic, epa_region

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


ReturnHeaders

ns_write "[bboard_header "Pick a state in region $epa_region"]

<h2>Pick a State</h2>

so that you can add a thread to 
<a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>.

<hr>

<ul>
"

set selection [ns_db select $db "select state_name, usps_abbrev
from bboard_epa_regions
where epa_region = $epa_region
order by upper(state_name)"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    ns_write "<li><a href=\"usgeospatial-post-new-2.tcl?[export_url_vars topic epa_region usps_abbrev]\">$state_name</a>\n"
}

ns_write "
</ul>


[bboard_footer]
"
