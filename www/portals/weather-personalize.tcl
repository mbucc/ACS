# /portals/weather-personalize.tcl
#

ad_page_contract {
    page to personalize cities for portal weather

    @author aileen@arsdigita.com
    @author randyg@arsdigita.com
    @creation-date January, 2000
    @cvs-id weather-personalize.tcl,v 3.4.2.6 2000/09/22 01:39:02 kevin Exp
} {
}


set user_id [ad_verify_and_get_user_id]

set page_content  "
[ad_header "Portals @ [ad_system_name]"]
<h2>Personalize Weather Information</h2>
[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] "Edit"]
<hr>
Your current list of cities:
<p>
"

set count 0

set sql_query "select * from portal_weather where user_id=:user_id"

db_foreach portal_weather_personalize_list_of_weather_info $sql_query {

    if {!$count} {
	append page_content "
	<table cellpadding=2>
	<tr>
	<th>City</th>
	<th>State</th>
	<th>Zip</th>
	<th>Type</th>
	</tr>"
    }

    set type ""

    if {$current_p=="t"} {
	append type "Current Conditions"
    } 

    if {$next_day_p=="t"} {
	if {[string length $type]>0} {
	    append type ", "
	}

	append type "Next Day Forecast"
    } 

    if {$five_day_p=="t"} {
	if {[string length $type]>0} {
	    append type ", "
	}

	append type "Five Day Forecast"
    }     

    append page_content "
    <tr>
    <td align=center>$city</td>
    <td align=center>$usps_abbrev</td>
    <td align=center>$zip_code</td>
    <td align=center>$type</td>
    <td align=right><a href=weather-delete?[export_url_vars weather_id]>remove</a></td>
    </tr>"

    incr count
}


if {$count} {
    append page_content  "</table>"
} else {
    append page_content  "
    You have not customized this portal table. Please add your cities below"
}


append page_content "
<p><h3>Add Cities</h3>
[AddCityWeatherWidget]
[ad_footer]
"



doc_return  200 text/html $page_content












