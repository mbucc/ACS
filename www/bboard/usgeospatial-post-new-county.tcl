# $Id: usgeospatial-post-new-county.tcl,v 3.0.4.1 2000/04/28 15:09:44 carsten Exp $
set_the_usual_form_variables

# fips_county_code, topic

# this always redirects to  state "see what's there" 
# or a state "add new posting" form if there isn't anything there

set db [ns_db gethandle]

set n_existing [database_to_tcl_string $db "select count(*) from bboard where fips_county_code = '$QQfips_county_code'"]

if { $n_existing > 0 } {
    ad_returnredirect "usgeospatial-one-county.tcl?[export_url_vars topic]&fips_county_code=[ns_urlencode $fips_county_code]"
} else {
    set usps_abbrev [database_to_tcl_string $db "select state from rel_search_co where fips_county_code='$QQfips_county_code'"]
    set epa_region [database_to_tcl_string $db "select epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
    ad_returnredirect "usgeospatial-post-new-3.tcl?[export_url_vars topic epa_region usps_abbrev fips_county_code]"
}


