# /portals/weather-delete-2.tcl

ad_page_contract {
    page to delete a city from the weather table

    @author aileen@arsdigita.com
    @author randyg@arsdigita.com
    @param weather_id 
    @param five_day_p
    @param next_day_p
    @creation-date January, 2000
    @cvs-id weather-delete-2.tcl,v 3.4.2.4 2000/07/21 04:03:24 ron Exp
} {
    weather_id:naturalnum
    {current_p "t"}
    {five_day_p "t"}
    {next_day_p "t"}
}

set user_id [ad_verify_and_get_user_id]

if {$current_p=="f" && $five_day_p=="f" && $next_day_p=="f"} {    
    db_dml portal_weather_delete_remove_weather_id "delete from portal_weather where weather_id=:weather_id"
} else {
    db_dml portal_weather_delete_update_weather "update portal_weather set current_p=:current_p, five_day_p=:five_day_p, next_day_p=:next_day_p where weather_id=:weather_id"
}

db_release_unused_handles
ad_returnredirect weather-personalize

