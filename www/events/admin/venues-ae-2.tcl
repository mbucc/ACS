set db [ns_db gethandle]


set_the_usual_form_variables
#venue_id, venue_name, address1, address2, city, usps_abbrev, postal_code, iso, needs_reserve_p, max_people, description, (maybe return_url)

#do some error checking
set exception_text ""
set exception_count 0

if {[exists_and_not_null max_people]} {
    if {[catch {set max_people [validate_integer "max_people" $max_people]} errmsg]} {
	incr exception_count
	append exception_text "<li>You must enter a number for maximum capacity"
    }
} else {
    set max_people "null"
}


if {![info exists venue_name] || [empty_string_p $venue_name]} {
    incr exception_count
    append exception_text "<li>You must name your venue"
}

if {![info exists city] || [empty_string_p $city]} {
    incr exception_count
    append exception_text "<li>You must enter a city"
}

if {![info exists iso] || [empty_string_p $iso]} {
    incr exception_count
    append exception_text "<li>You must select a country"
}

if {[string compare $iso "us"] == 0} {
    if {![info exists usps_abbrev] || [empty_string_p $usps_abbrev]} {
	incr exception_count
	append exception_text "<li>You must enter a state"
    }
}

if {$exception_count > 0} {
    ad_return_complaint $exception_count $exception_text
    return
}

if {![info exists needs_reserve_p] } {
    set needs_reserve_p "f"
}

ns_db dml $db "begin transaction"

ns_db dml $db "update events_venues set
venue_name='$QQvenue_name',
address1='$QQaddress1',
address2='$QQaddress2',
city='$QQcity',
usps_abbrev='$usps_abbrev',
postal_code='$QQpostal_code',
iso='$QQiso',
needs_reserve_p='$needs_reserve_p',
max_people=$max_people,
description='$QQdescription'
where venue_id=$venue_id"

if {[ns_ora resultrows $db] == 0} {
    ns_db dml $db "insert into events_venues
    (venue_id, venue_name, address1, address2, city, usps_abbrev, postal_code,
    iso, needs_reserve_p, max_people, description)
    values
    ($venue_id, '$QQvenue_name', '$QQaddress1', '$QQaddress2', '$QQcity',
    '$usps_abbrev', '$QQpostal_code', '$iso', '$needs_reserve_p',
    $max_people, '$QQdescription')"
}

#create the user group for this venue

ns_db dml $db "end transaction"

if {[info exists return_url] && ![empty_string_p $return_url]} {
    ad_returnredirect "$QQreturn_url&[export_url_vars venue_id]"
} else {
    ad_returnredirect "venues.tcl"
}
