# /portals/weather-personalize.tcl
#
# page to personalize cities for portal weather
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle] 

set selection [ns_db select $db "select * from portal_weather where user_id=$user_id"]

ReturnHeaders

ns_write "
[ad_header "Portals @ [ad_system_name]"]
<h2>Personalize Weather Information</h2>
[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] "Edit"]
<hr>
Your current list of cities:
<p>
"

set count 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    
    if {!$count} {
	ns_write "
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

    ns_write "
    <tr>
    <td align=center>$city</td>
    <td align=center>$usps_abbrev</td>
    <td align=center>$zip_code</td>
    <td align=center>$type</td>
    <td align=right><a href=weather-delete.tcl?[export_url_vars weather_id]>remove</a></td>
    </tr>"

    incr count
}

if {$count} {
    ns_write "</table>"
} else {
    ns_write "
    You have not customized this portal table. Please add your cities below"
}

ns_write "
<p><h3>Add Cities</h3>
[AddCityWeatherWidget $db]
[ad_footer]
"








