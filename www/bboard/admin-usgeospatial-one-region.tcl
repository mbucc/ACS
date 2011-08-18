# $Id: admin-usgeospatial-one-region.tcl,v 3.0 2000/02/06 03:33:27 ron Exp $
set_the_usual_form_variables

# topic required

if ![msie_p] { 
    set target_window "target=admin_bboard_window" 
} else { 
    set target_window ""
}

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}



set sql "select bboard.*, facility, email, first_names || ' ' || last_name as name, interest_level
from bboard, users, rel_search_fac
where bboard.user_id = users.user_id 
and epa_region = '$QQepa_region'
and topic_id = $topic_id
and refers_to is null
and bboard.tri_id = rel_search_fac.tri_id(+)
order by sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

ReturnHeaders

ns_write "<html>
<head>
<title>Administer $topic by Region</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Administer $topic</h2>

by region"

if { $backlink != "" || $backlink_title != "" } {

	ns_write " associated with
<a href=\"$backlink\" target=\"_top\">$backlink_title</a>."

}

ns_write "

<hr>

<ul>

"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a> (<a href=usgeospatial-2.tcl?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : <a href=usgeospatial-one-state.tcl?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : <a href=usgeospatial-one-county.tcl?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a> : <a href=/env-releases/facility.tcl?tri_id=$tri_id>$tri_id : $facility</a>)
<br>
from $name (<a href=\"mailto:$email\">$email</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	ns_write " -- interest level $interest_level"
    }

}

ns_write "

</ul>

[bboard_footer]
"
