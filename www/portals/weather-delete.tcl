# /portals/weather-delete.tcl

ad_page_contract {
    page to delete a city from the weather table

    @author aileen@arsdigita.com, randyg@arsdigita.com
    @creation_date January, 2000
    @param weather_id    
    @cvs-id weather-delete.tcl,v 3.4.2.5 2000/09/22 01:39:02 kevin Exp
} {
    {weather_id:naturalnum,notnull}
}

set user_id [ad_verify_and_get_user_id]

set sql_query  "select * from portal_weather where weather_id=:weather_id"

db_foreach portal_weather_delete_list_of_weather_info $sql_query  {
    
    set page_content "
    [ad_header "Portals @ [ad_system_name]"]
    <h2>Delete $city, $usps_abbrev</h2>
    [ad_context_bar_ws [list /portals/user$user_id-1.ptl "Portal"] [list /portals/weather-personalize"Edit Weather"] "Delete a City"]
    <hr>
    You are currently receiving the following weather information about this city. Check the information you wish to <b>remove</b>.
    <p>
    <form method=post action=/portals/weather-delete-2>
    [ec_decode $current_p "t" "<input type=checkbox name=current_p value=f checked>Current Conditions &nbsp;&nbsp;&nbsp;&nbsp;" "<input type=hidden name=current_p value=f>"]
    [ec_decode $next_day_p "t" "<input type=checkbox name=next_day_p value=f>Next Day Forecast &nbsp;&nbsp;&nbsp;&nbsp;" "<input type=hidden name=next_day_p value=f>"]
    [ec_decode $five_day_p "t" "<input type=checkbox name=five_day_p value=f>Five Day Forecast" "<input type=hidden name=five_day_p value=f>"]
    <p>
    [export_form_vars weather_id]
    <input type=submit value=Continue>
    </form>
    [ad_footer]
    "
}


doc_return  200 text/html $page_content













