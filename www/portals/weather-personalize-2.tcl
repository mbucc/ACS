###### THIS IS THE VERSION OF WEATHER PERSONALIZE WE SHOULD USE
###### FOR ACS RELEASES BECAUSE IT DOES NOT USE THE ZIP_CODES TABLE

# /portals/weather-personalize-2.tcl
#
# page to personalize cities for portal weather
#
# aileen@arsdigita.com, randyg@arsdigita.com
#
# January, 2000

# weather_id city, usps_abbrev or zip_code
# (optional) next_day_p, five_day_p, current_p 

ad_page_variables {
    weather_id
    {next_day_p f}
    {five_day_p f}
    {current_p f}
    {city ""}
    {usps_abbrev ""}
    {zip_code ""}
}

set user_id [ad_verify_and_get_user_id]

set db [ns_db gethandle]

set exception_count 0
set exception_text ""
set by_zip 0

if {[empty_string_p $zip_code]} {
    if {[empty_string_p $city] || [empty_string_p $usps_abbrev]} {
	incr exception_count
	append exception_text "<li>You must enter a zip code or both the city and state."
    } 
} else {
    set by_zip 1
}

if {$next_day_p=="f" && $five_day_p=="f" && $current_p=="f"} {
    incr exception_count
    append exception_text "<li>You must select at least one information type"
}

if {$exception_count>0} {
    ad_return_complaint $exception_count $exception_text
    return
}
    
#### Comment out because we can't release the module with the zip_codes table
# if {$by_zip} {

if 0 {
    # returns a list of city and usps_abbrev based on zip_code or empty list
    # if there's more than one city and redirects to another page for user to
    # choose city.
    set selection [ns_db select $db "select state_code, city_name from zip_codes where zip_code=$zip_code"]

    set count 0
    set city_state_lst [list]

    while {[ns_db getrow $db $selection]} {
	set_variables_after_query
	
	lappend city_state_lst [list $city_name $state_code]
	incr count
    }
    
    if {$count>1} {
	set final_url [ns_conn url]?[export_entire_form_as_url_vars]
	# we're feeding another page to the user because zip_code generated >1 city
	ad_returnredirect /portals/city-select.tcl?[export_url_vars final_url city_state_lst zip_code]
	return
    }

    set city [lindex [lindex $city_state_lst 0] 0]
    set usps_abbrev [lindex [lindex $city_state_lst 0] 1]
}

ns_db dml $db "insert into portal_weather (weather_id, user_id, city, usps_abbrev, zip_code, five_day_p, next_day_p, current_p) values ($weather_id, $user_id, '$city', '$usps_abbrev', '$zip_code', '$five_day_p', '$next_day_p', '$current_p')"

ad_returnredirect /portals/weather-personalize.tcl
