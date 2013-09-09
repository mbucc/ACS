# /www/bboard/usgeospatial-post-new-3.tcl
ad_page_contract {
    Posts a new message in the geospatial bboard system

    @param topic the name of the bboard topic
    @param epa_region the region of the country
    @param usps_abbrev the postal abbreviation of the state
    @param fips_county_code the ID for the county

    @cvs-id usgeospatial-post-new-3.tcl,v 3.3.2.6 2000/09/22 01:36:57 kevin Exp
} {
    topic:notnull
    epa_region:integer,notnull
    usps_abbrev:notnull
    fips_county_code:optional,integer
}

# -----------------------------------------------------------------------------

if {[bboard_get_topic_info] == -1} {
    return
}

#check for the user cookie

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

# we know who this is

if [info exists fips_county_code] {
    append pretty_location [db_string county_name "
    select fips_county_name 
    from counties 
    where fips_county_code = :fips_county_code"] " County, " [db_string \
	    state_name "
    select state_name from states 
    where usps_abbrev = :usps_abbrev"]
} else {
    set pretty_location [db_string state_name "
    select state_name from states where usps_abbrev = :usps_abbrev"]
}

set menubar_items [list]
lappend menubar_items "<a href=\"usgeospatial-search-form?[export_url_vars topic topic_id]\">Search</a>"

lappend menubar_items "<a href=\"help?[export_url_vars topic topic_id]\">Help</a>"

set top_menubar [join $menubar_items " | "]

append page_content "
[bboard_header "Post New Message"]

<h2>Post a New Message</h2>

about $pretty_location into <a href=\"usgeospatial-2?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>.

<hr>

\[$top_menubar\]

<br>
<br>

<form method=post action=\"insert-msg\" target=\"_top\">
[export_form_vars topic epa_region usps_abbrev fips_county_code]

[philg_hidden_input usgeospatial_p t]
[philg_hidden_input refers_to NEW]

<table cellspacing=6>

<tr><th>Subject Line<td><input type=text name=one_line size=50></tr>

<tr><th>Notify Me of Responses
<td><input type=radio name=notify value=t CHECKED> Yes
<input type=radio name=notify value=f> No

<tr><th>Message<td>&nbsp;</tr>

</table>

<blockquote>

<textarea name=message rows=10 cols=70 wrap=hard></textarea>
</blockquote>

<P>

<center>

<input type=submit value=\"Post\">

</center>

</form>

[bboard_footer]
"

doc_return  200 text/html $page_content