# $Id: admin-usgeospatial.tcl,v 3.0 2000/02/06 03:33:30 ron Exp $
set_form_variables_string_trim_DoubleAposQQ
set_form_variables

# topic required

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}

 
if  {[bboard_get_topic_info] == -1} {
    return}

if {[bboard_admin_authorization] == -1} {
	return}







# the administrator can always post a new question

set ask_a_question "<a href=\"usgeospatial.tcl?[export_url_vars topic topic_id]\">Post a New Message</a> |"

if { $policy_statement != "" } {
    set about_link "| <a href=\"policy.tcl?[export_url_vars topic topic_id]\">About</a>"
} else {
    set about_link ""
}

if { [bboard_pls_blade_installed_p] } {
    set top_menubar "\[ $ask_a_question
<a href=\"usgeospatial-search-form.tcl?[export_url_vars topic topic_id]\">Search</a> 
$about_link
\]"
} else {
    set top_menubar "\[ $ask_a_question
$about_link
 \]"
}

set sql "select bboard.*, facility, users.email, users.first_names || ' ' || users.last_name as name, interest_level
from bboard, users, rel_search_fac
where users.user_id = bboard.user_id 
and topic_id = $topic_id
and refers_to is null
and posting_time > (sysdate - $q_and_a_new_days)
and bboard.tri_id = rel_search_fac.tri_id(+)
order by sort_key $q_and_a_sort_order"

set selection [ns_db select $db $sql]

ReturnHeaders

ns_write "<html>
<head>
<title>Administer $topic by Question</title>
</head>
<body bgcolor=[ad_parameter bgcolor "" "white"] text=[ad_parameter textcolor "" "black"]>

<h2>Administer $topic</h2>

by question (one of the options from <a href=\"admin-home.tcl?[export_url_vars topic topic_id]\">the admin home page for this topic</a>)

<hr>

$top_menubar

<h3>New Threads</h3>


<ul>

"

while {[ns_db getrow $db $selection]} {
    set_variables_after_query

    ns_write "<li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg.tcl?msg_id=$msg_id\">$one_line</a> (<a href=usgeospatial-2.tcl?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : <a href=usgeospatial-one-state.tcl?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : <a href=usgeospatial-one-county.tcl?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a> : <a href=/env-releases/facility.tcl?tri_id=$tri_id>$tri_id : $facility</a>)
<br>
from  (<a href=\"mailto:$email\">$name</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	ns_write " -- interest level $interest_level"
    }

}

ns_write "

</ul>

<h3>Other Groups of Posts</h3>

<ul>
<li><a href=\"admin-usgeospatial-all.tcl?[export_url_vars topic topic_id]\">All the Posts</a>
<!-- <li><a href=\"admin-q-and-a-category-list.tcl?[export_url_vars topic topic_id]\">Pick a Region</a> -->
<li><a href=\"admin-usgeospatial-pick-a-region.tcl?[export_url_vars topic topic_id]\">Pick a Region</a>
<li><a href=\"admin-usgeospatial-new-messages.tcl?[export_url_vars topic topic_id]\">New Posts</a> (organized chronologically)

</ul> 

"
ns_write "

[bboard_footer]
"
