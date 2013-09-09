# /portals/weather-personalize-2.tcl
#

ad_page_contract {
    page to personalize cities for portal weather


    @author aileen@arsdigita.com, randyg@arsdigita.com
    @creation-date January, 2000
    @param weather_id 
    @param city 
    @param usps_abbrev 
    @param zip_code
    @param next_day_p
    @param five_day_p
    @param current_p 
    @cvs-id weather-personalize-2.tcl,v 3.3.2.6 2000/07/21 04:03:25 ron Exp

    ###### THIS IS THE VERSION OF WEATHER PERSONALIZE WE SHOULD USE
    ###### FOR ACS RELEASES BECAUSE IT DOES NOT USE THE ZIP_CODES TABLE
} {
    weather_id:naturalnum,notnull
    {next_day_p f}
    {five_day_p f}
    {current_p f}
    city:optional
    usps_abbrev:optional
    zip_code:optional
}


set user_id [ad_verify_and_get_user_id]

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
    set sql "select state_code, city_name from zip_codes where zip_code = :zip_code"

    set count 0
    set city_state_lst [list]

    db_foreach portal_weather_personalize_get_city_name $sql {
	lappend city_state_lst [list $city_name $state_code]
	incr count
    }
    
    if {$count>1} {
	set final_url [ns_conn url]?[export_entire_form_as_url_vars]
	# we're feeding another page to the user because zip_code generated >1 city
	ad_returnredirect /portals/city-select?[export_url_vars final_url city_state_lst zip_code]
	return
    }

    set city [lindex [lindex $city_state_lst 0] 0]
    set usps_abbrev [lindex [lindex $city_state_lst 0] 1]
}

db_dml portal_weather_personalize_insert_row "insert into portal_weather (weather_id, user_id, city, usps_abbrev, zip_code, five_day_p, next_day_p, current_p) values (:weather_id, :user_id, :city, :usps_abbrev, :zip_code, :five_day_p, :next_day_p, :current_p)"

db_release_unused_handles
ad_returnredirect /portals/weather-personalize
