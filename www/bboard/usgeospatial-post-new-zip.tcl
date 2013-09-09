# /www/bboard/usgeospatial-post-new-zip.tcl
ad_page_contract {
    this always redirects to either county or state "see what's there" 
    or a county "add new posting" form if there isn't anything there

    @para zip_code the new zip code
    @param topic the name of the bboard topic

    @cvs-id usgeospatial-post-new-zip.tcl,v 3.1.6.5 2000/07/21 23:59:51 kevin Exp
} {
    zip_code:notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

if {! [db_0or1row zip_info "
select distinct geo_area_id, geo_area_type 
from cmy_search_zip where sema_zip = :zip_code"]} {

    ad_returnredirect "usgeospatial.tcl?[export_url_vars topic]"
    return
}

if { $geo_area_type == "fips_state_code" } {
    db_1row usps_abbrev "
    select usps_abbrev from states where fips_state_code = :geo_area_id"
    set n_existing [db_string num_state_msgs "
    select count(*) from bboard where usps_abbrev = :usps_abbrev"]
    if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-state.tcl?[export_url_vars topic usps_abbrev]"
    } else {
	db_1row epa_region "
	select epa_region from bboard_epa_regions 
	where usps_abbrev = :usps_abbrev"
	ad_returnredirect "usgeospatial-post-new-2.tcl?[export_url_vars topic usps_abbrev epa_region]"
    }
} else {
    # county code
    set n_existing [db_string num_county_msgs "
    select count(*) from bboard where fips_county_code = :geo_area_id"]
    if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-county.tcl?[export_url_vars topic]&fips_county_code=[ns_urlencode $geo_area_id]"
    } else {
	db_1row usps_abbrev_from_co "
	select usps_abbrev from counties where fips_county_code=:geo_area_id"
	db_1row epa_region "
	select epa_region from bboard_epa_regions 
	where usps_abbrev = :usps_abbrev"
	set fips_county_code $geo_area_id
	ad_returnredirect "usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]"
    }
}

