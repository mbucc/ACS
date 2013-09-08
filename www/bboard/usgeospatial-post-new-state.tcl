# /www/bboard/usgeospatial-post-new-state.tcl
ad_page_contract {
    this always redirects to  state "see what's there" 
    or a state "add new posting" form if there isn't anything there

    @param usps_abbrev the postal abbreviation for the state
    @param topic the name of the bboard topic

    @cvs-id usgeospatial-post-new-state.tcl,v 3.2.2.3 2000/07/21 03:58:54 ron Exp
} {
    usps_abbrev:notnull
    topic:notnull
}

# -----------------------------------------------------------------------------

set n_existing [db_string n_existing "
select count(*) from bboard where usps_abbrev = :usps_abbrev"]

if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-state.tcl?[export_url_vars topic usps_abbrev]"
} else {
    db_1row epa_region "
    select epa_region from bboard_epa_regions 
    where usps_abbrev = :usps_abbrev"
    ad_returnredirect "usgeospatial-post-new-2.tcl?[export_url_vars topic usps_abbrev epa_region]"
}
