# /www/bboard/admin-usgeospatial.tcl
ad_page_contract {
    View one topic in the geospatial bboard system

    @param topic the name of the bboard topic

    @cvs-id admin-usgeospatial.tcl,v 3.2.2.4 2000/09/22 01:36:47 kevin Exp
} {
    topic:notnull
}

# -----------------------------------------------------------------------------
 
if  {[bboard_get_topic_info] == -1} {
    return
}

if {[bboard_admin_authorization] == -1} {
	return
}

# the administrator can always post a new question

set ask_a_question "<a href=\"usgeospatial?[export_url_vars topic topic_id]\">Post a New Message</a> |"

if { $policy_statement != "" } {
    set about_link "| <a href=\"policy?[export_url_vars topic topic_id]\">About</a>"
} else {
    set about_link ""
}

if { [bboard_pls_blade_installed_p] } {
    set top_menubar "\[ $ask_a_question
<a href=\"usgeospatial-search-form?[export_url_vars topic topic_id]\">Search</a> 
$about_link
\]"
} else {
    set top_menubar "\[ $ask_a_question
$about_link
 \]"
}

append page_content "
[ad_admin_header "Administer $topic by Question"]

<h2>Administer $topic</h2>

by question (one of the options from <a href=\"admin-home?[export_url_vars topic topic_id]\">the admin home page for this topic</a>)

<hr>

$top_menubar

<h3>New Threads</h3>

<ul>

"

set sql "
select bboard.*, 
       users.email, 
       users.first_names || ' ' || users.last_name as name,
       interest_level
from   bboard, 
       users
where  users.user_id = bboard.user_id 
and    topic_id = :topic_id
and    refers_to is null
and    posting_time > (sysdate - :q_and_a_new_days)
order by sort_key $q_and_a_sort_order"

db_foreach new_bboard_posting $sql {

    append page_content "
    <li><a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a> (<a href=usgeospatial-2?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : <a href=usgeospatial-one-state?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : <a href=usgeospatial-one-county?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a>)
<br>
from  (<a href=\"mailto:$email\">$name</a>)\n"
    if { $q_and_a_use_interest_level_p == "t" } {
	if { $interest_level == "" } { set interest_level "NULL" }
	append page_content " -- interest level $interest_level"
    }

}

append page_content "

</ul>

<h3>Other Groups of Posts</h3>

<ul>
<li><a href=\"admin-usgeospatial-all?[export_url_vars topic topic_id]\">All the Posts</a>
<!-- <li><a href=\"admin-q-and-a-category-list?[export_url_vars topic topic_id]\">Pick a Region</a> -->
<li><a href=\"admin-usgeospatial-pick-a-region?[export_url_vars topic topic_id]\">Pick a Region</a>
<li><a href=\"admin-usgeospatial-new-messages?[export_url_vars topic topic_id]\">New Posts</a> (organized chronologically)

</ul> 

[bboard_footer]
"

doc_return  200 text/html $page_content

