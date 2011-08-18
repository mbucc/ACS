# $Id: usgeospatial-post-new-zip.tcl,v 3.0.4.1 2000/04/28 15:09:45 carsten Exp $
set_the_usual_form_variables

# zip_code, topic

# this always redirects to either county or state "see what's there" 
# or a county "add new posting" form if there isn't anything there

set db [ns_db gethandle]

set selection [ns_db 0or1row $db "select distinct geo_area_id, geo_area_type from cmy_search_zip where sema_zip = '$QQzip_code'"]

if [empty_string_p $selection] {
    ad_returnredirect "usgeospatial.tcl?[export_url_vars topic]"
    return
}

set_variables_after_query

if { $geo_area_type == "fips_state_code" } {
    set usps_abbrev [database_to_tcl_string $db "select state from rel_search_st where fips_state_code = '$geo_area_id'"]
    set n_existing [database_to_tcl_string $db "select count(*) from bboard where usps_abbrev = '$usps_abbrev'"]
    if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-state.tcl?[export_url_vars topic usps_abbrev]"
    } else {
	set epa_region [database_to_tcl_string $db "select epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
	ad_returnredirect "usgeospatial-post-new-2.tcl?[export_url_vars topic usps_abbrev epa_region]"
    }
} else {
    # county code
    set n_existing [database_to_tcl_string $db "select count(*) from bboard where fips_county_code = '$geo_area_id'"]
    if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-county.tcl?[export_url_vars topic]&fips_county_code=[ns_urlencode $geo_area_id]"
    } else {
	set usps_abbrev [database_to_tcl_string $db "select state from rel_search_co where fips_county_code='$geo_area_id'"]
	set epa_region [database_to_tcl_string $db "select epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
	set fips_county_code $geo_area_id
	ad_returnredirect "usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]"
    }
}

