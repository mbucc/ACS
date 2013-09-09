# /www/bboard/admin-usgeospatial-new-messages.tcl
ad_page_contract {
    Display new messages in the geospatial bboard system

    @param topic the name of the bboard topic

    @cvs-id admin-usgeospatial-new-messages.tcl,v 3.2.2.4 2000/09/22 01:36:47 kevin Exp
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

append page_content "
[ad_admin_header "$topic Recent Postings"]

<h2>Recent Postings</h2>

in the <a href=\"admin-home?[export_url_vars topic topic_id]\">$topic Q&A forum</a> (sorted by time rather than by thread)

<p>

(covers last $q_and_a_new_days days)

<hr>

<ul>
"

db_foreach new_postings "
select bboard.*, 
       email, 
       first_names || ' ' || last_name as name, 
       originating_ip, 
       interest_level, 
       posting_time, 
       substr(sort_key,1,6) as root_msg_id
from   bboard, users
where   bboard.user_id = users.user_id
and     topic = :topic_id
and     posting_time > sysdate - :q_and_a_new_days
order by sort_key desc" {

    if { $originating_ip == "" } {
	set ip_stuff ""
    } else {
	set ip_stuff "<a href=\"admin-view-one-ip?originating_ip=[ns_urlencode $originating_ip]&[export_url_vars topic topic_id]\">$originating_ip</a>"
    }
    append page_content "<li>$posting_time: <a target=admin_bboard_window href=\"admin-q-and-a-fetch-msg?msg_id=$msg_id\">$one_line</a> (<a href=usgeospatial-2?[export_url_vars topic topic_id]&epa_region=$epa_region>$epa_region</a> : <a href=usgeospatial-one-state?[export_url_vars topic topic_id]&usps_abbrev=$usps_abbrev>$usps_abbrev</a> : <a href=usgeospatial-one-county?[export_url_vars topic topic_id]&fips_county_code=$fips_county_code>$fips_county_code</a>) from $name 
(<a href=\"admin-view-one-email?email=[ns_urlencode $email]&[export_url_vars topic topic_id]\">$email) 
$ip_stuff"

}

append page_content "

</ul>

[bboard_footer]
"


doc_return  200 text/html $page_content