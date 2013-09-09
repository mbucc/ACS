# /www/bboard/admin-usgeospatial-one-region.tcl
ad_page_contract {
    View postings for one region in a bboard topic

    @param topic the name of the bboard topic

    @cvs-id admin-usgeospatial-one-region.tcl,v 3.2.2.5 2000/09/22 01:36:47 kevin Exp
} {
    topic:notnull
    epa_region:integer
}

# -----------------------------------------------------------------------------

if ![msie_p] { 
    set target_window "target=admin_bboard_window" 
} else { 
    set target_window ""
}
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
    return
}

append page_content "
[ad_admin_header "Administer $topic by Region"]

<h2>Administer $topic</h2>

by region"

if { $backlink != "" || $backlink_title != "" } {

    append page_content " associated with
<a href=\"$backlink\" target=\"_top\">$backlink_title</a>."

}

append page_content "

<hr>

<ul>

"

set sql "
select bboard.*, 
       email, 
       first_names || ' ' || last_name as name, 
       interest_level
from   bboard, users
where  bboard.user_id = users.user_id 
and    epa_region = :epa_region
and    topic_id = :topic_id
and    refers_to is null
order by sort_key $q_and_a_sort_order"

db_foreach postings_for_one_region $sql {

    append page_content "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a> (<a href=usgeospatial-2?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : <a href=usgeospatial-one-state?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : <a href=usgeospatial-one-county?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a>)
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	append page_content " -- interest level $interest_level"
    }

}

append page_content "

</ul>

[bboard_footer]
"

doc_return  200 text/html $page_content
