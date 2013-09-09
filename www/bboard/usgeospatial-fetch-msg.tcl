# /www/bboard/usgeospatial-fetch-msg.tcl
ad_page_contract {
    Gets one message

    @param msg_id the ID of the message

    @cvs-id usgeospatial-fetch-msg.tcl,v 3.1.6.9 2000/09/22 01:36:56 kevin Exp
} {
    msg_id:notnull
}

# -----------------------------------------------------------------------------

# make a copy because it is going to get overwritten by 
# some subsequent queries

set this_msg_id $msg_id


if {![db_0or1row msg_info "
select to_char(posting_time,'Month dd, yyyy') as posting_date,
       bboard.*, 
       users.user_id as poster_id,  
       users.first_names || ' ' || users.last_name as name, 
       fips_county_name, 
       states.state_name
from   bboard, 
       users, 
       counties, 
       states
where  bboard.user_id = users.user_id
and    bboard.fips_county_code = counties.fips_county_code(+)
and    bboard.usps_abbrev = states.usps_abbrev
and    msg_id = :msg_id"]} {

    # message was probably deleted
    doc_return  200 text/html "Couldn't find message $msg_id.  Probably it was deleted by the forum maintainer."
    return
}

set this_one_line $one_line

# now variables like $message and $topic are defined

if {[bboard_get_topic_info] == -1} {
    return
}

set contributed_by "-- <a href=\"contributions?user_id=$poster_id\">$name</a>, $posting_date."

# These files don't even exist!

if { ![empty_string_p $zip_code] } {
    set about_text "Zip Code $zip_code"
#    set about_link "Zip Code <a href=\"/env-releases/zip-code?[export_url_vars zip_code]\">$zip_code</a>"
} elseif { ![empty_string_p $fips_county_code] } {
    set about_text "$fips_county_name County"
#    set about_link "<a href=\"/env-releases/county?[export_url_vars fips_county_code]\">$fips_county_name County</a>"
} elseif { ![empty_string_p $usps_abbrev] } {
    set about_text "$state_name"
#    set about_link "<a href=\"/env-releases/state?[export_url_vars usps_abbrev]\">$state_name</a>"
}


append page_content "
[bboard_header $about_text]

<h3>Discussion</h3>

about $about_text in <a href=\"usgeospatial-2?[export_url_vars topic topic_id epa_region]\">the $topic (Region $epa_region) forum</a>
in <a href=\"[ad_pvt_home]\">[ad_system_name]</a>
<hr>

<h4>$one_line</h4>
<blockquote>
[ad_convert_to_html -html_p f $message]
<br><br>
$contributed_by
</blockquote>
"

bboard_get_topic_info
set msg_id_base "$msg_id%"

db_foreach responses "
select decode(email,:maintainer_email,'f','t') as not_maintainer_p, 
       to_char(posting_time,'Month dd, yyyy') as posting_date, 
       bboard.*, 
       users.user_id as replyer_user_id,
       users.first_names || ' ' || users.last_name as name, 
       users.email 
from   bboard, users
where  users.user_id = bboard.user_id
and    sort_key like :msg_id_base
and    msg_id <> :msg_id
order by not_maintainer_p, sort_key" {

    set contributed_by "-- <a href=\"contributions?user_id=$replyer_user_id\">$name</a>, $posting_date"

    set this_response ""
    if { $one_line != $this_one_line && $one_line != "Response to $this_one_line" } {
	# new subject
	append this_response "<h4>$one_line</h4>\n"
    } else {
	append this_response "<br><br>\n"
    }
    append this_response "<blockquote>
$message
<br>
<br>
$contributed_by
</blockquote>
"
    lappend responses $this_response
}

if { [info exists responses] } {
    # there were some
    append page_content "[join $responses "\n\n"]\n"
}
    
append page_content "

<br>
<br>

<center>
<form method=get action=usgeospatial-post-reply-form>
<input type=hidden name=refers_to value=\"$this_msg_id\">
<input type=submit value=\"Post a response\"</a>
</form>
</center>

&nbsp;
&nbsp;
&nbsp;

or start a new thread about

<a href=\"usgeospatial-post-new?[export_url_vars topic epa_region]\">Region $epa_region</a> :
<a href=\"usgeospatial-post-new-2?[export_url_vars topic epa_region usps_abbrev]\">$state_name</a>

"

if ![empty_string_p $fips_county_code] {
    append page_content ": <a href=\"usgeospatial-post-new-3?[export_url_vars topic epa_region usps_abbrev fips_county_code]\">$fips_county_name County</a>"

}

append page_content "

[bboard_footer]
"

doc_return 200 text/html $page_content








