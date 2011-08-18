# $Id: usgeospatial-post-new-3.tcl,v 3.0.4.1 2000/04/28 15:09:44 carsten Exp $
set_the_usual_form_variables

# topic, epa_region, usps_abbrev, fips_county_code (optional) 

set db [bboard_db_gethandle]
if { $db == "" } {
    bboard_return_error_page
    return
}


if {[bboard_get_topic_info] == -1} {
    return
}


#check for the user cookie

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
   ad_returnredirect /register.tcl?return_url=[ns_urlencode "[bboard_partial_url_stub]usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]"]
    return
}

# we know who this is

if [info exists fips_county_code] {
    append pretty_location [database_to_tcl_string $db "select fips_county_name from rel_search_co where fips_county_code = '$QQfips_county_code'"] " County, " [database_to_tcl_string $db "select state_name from rel_search_st where state = '$QQusps_abbrev'"]
} else {
    set pretty_location [database_to_tcl_string $db "select state_name from rel_search_st where state = '$QQusps_abbrev'"]
}

set menubar_items [list]
lappend menubar_items "<a href=\"usgeospatial-search-form.tcl?[export_url_vars topic topic_id]\">Search</a>"

lappend menubar_items "<a href=\"help.tcl?[export_url_vars topic topic_id]\">Help</a>"

set top_menubar [join $menubar_items " | "]

ReturnHeaders

ns_write "[bboard_header "Post New Message"]

<h2>Post a New Message</h2>

about $pretty_location into <a href=\"usgeospatial-2.tcl?[export_url_vars topic epa_region]\">the $topic (region $epa_region) forum</a>.

<hr>

\[$top_menubar\]

<br>
<br>


<form method=post action=\"insert-msg.tcl\" target=\"_top\">
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
