# /portals/weather-delete-2.tcl
#
# page to delete a city from the weather table
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

ad_page_variables {
    weather_id
    {current_p "t"}
    {five_day_p "t"}
    {next_day_p "t"}
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

if {$current_p=="f" && $five_day_p=="f" && $next_day_p=="f"} {    
    ns_db dml $db "delete from portal_weather where weather_id=$weather_id"
} else {
    ns_db dml $db "update portal_weather set current_p='$current_p', five_day_p='$five_day_p', next_day_p='$next_day_p' where weather_id=$weather_id"
}

ad_returnredirect weather-personalize.tcl


