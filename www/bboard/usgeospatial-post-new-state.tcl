# $Id: usgeospatial-post-new-state.tcl,v 3.0.4.1 2000/04/28 15:09:44 carsten Exp $
set_the_usual_form_variables

# usps_abbrev, topic

# this always redirects to  state "see what's there" 
# or a state "add new posting" form if there isn't anything there

set db [ns_db gethandle]

set n_existing [database_to_tcl_string $db "select count(*) from bboard where usps_abbrev = '$usps_abbrev'"]

if { $n_existing > 0 } {
	ad_returnredirect "usgeospatial-one-state.tcl?[export_url_vars topic usps_abbrev]"
} else {
    set epa_region [database_to_tcl_string $db "select epa_region from bboard_epa_regions where usps_abbrev = '$usps_abbrev'"]
    ad_returnredirect "usgeospatial-post-new-2.tcl?[export_url_vars topic usps_abbrev epa_region]"
}
