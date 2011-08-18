# /portals/weather-delete.tcl
#
# page to delete a city from the weather table
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

# weather_id

ad_page_variables {weather_id}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set selection [ns_db 1row $db "select * from portal_weather where weather_id=$weather_id"]

set_variables_after_query

ReturnHeaders 

ns_write "
[ad_header "Portals @ [ad_system_name]"]
<h2>Delete $city, $usps_abbrev</h2>
[ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] [list /portals/weather-personalize.tcl "Edit Weather"] "Delete a City"]
<hr>
You are currently receiving the following weather information about this city. Check the information you wish to <b>remove</b>.
<p>
<form method=post action=/portals/weather-delete-2.tcl>
[ec_decode $current_p "t" "<input type=checkbox name=current_p value=f checked>Current Conditions &nbsp;&nbsp;&nbsp;&nbsp;" "<input type=hidden name=current_p value=f>"]
[ec_decode $next_day_p "t" "<input type=checkbox name=next_day_p value=f>Next Day Forecast &nbsp;&nbsp;&nbsp;&nbsp;" "<input type=hidden name=next_day_p value=f>"]
[ec_decode $five_day_p "t" "<input type=checkbox name=five_day_p value=f>Five Day Forecast" "<input type=hidden name=five_day_p value=f>"]
<p>
[export_form_vars weather_id]
<input type=submit value=Continue>
</form>
[ad_footer]
"


