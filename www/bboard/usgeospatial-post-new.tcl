# /www/bboard/usgeospatial-post-new.tcl
ad_page_contract {
    Post a new message in a particular topic/region

    @param topic the name of the bboard topic
    @param epa_region the region of the country

    @cvs-id usgeospatial-post-new.tcl,v 3.1.6.3 2000/09/22 01:36:57 kevin Exp
} {
    topic:notnull
    epa_region:notnull
}

# -----------------------------------------------------------------------------

if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

if {[bboard_get_topic_info] == -1} {
    return
}

append page_content "
[bboard_header "Pick a state in region $epa_region"]

<h2>Pick a State</h2>

so that you can add a thread to 
<a href=\"usgeospatial-2?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>.

<hr>

<ul>
"

db_foreach names_abbrevs "
select state_name, usps_abbrev
from   bboard_epa_regions
where  epa_region = :epa_region
order by upper(state_name)" {

    append page_content "<li><a href=\"usgeospatial-post-new-2?[export_url_vars topic epa_region usps_abbrev]\">$state_name</a>\n"
}

append page_content "
</ul>


[bboard_footer]
"

doc_return  200 text/html $page_content
