# /www/bboard/usgeospatial-post-new-county.tcl
ad_page_contract {
    this always redirects to  state "see what's there" 
    or a state "add new posting" form if there isn't anything there

    @param topic the name of the bboard topic
    @param fips_county_code the ID string for the county

    @cvs-id usgeospatial-post-new-county.tcl,v 3.1.6.5 2000/07/21 23:59:51 kevin Exp
} {
    fips_county_code:notnull
    topic:notnull
}

# -----------------------------------------------------------------------------


set n_existing [db_string n_existing "
select count(*) from bboard where fips_county_code = :fips_county_code"]

if { $n_existing > 0 } {
    ad_returnredirect "usgeospatial-one-county.tcl?[export_url_vars topic]&fips_county_code=[ns_urlencode $fips_county_code]"
} else {
    db_1row usps_abbrev "
    select usps_abbrev from counties 
    where fips_county_code= :fips_county_code"]
    set epa_region [db_string region "
    select epa_region from bboard_epa_regions 
    where usps_abbrev = :usps_abbrev"]
    ad_returnredirect "usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]"
}


