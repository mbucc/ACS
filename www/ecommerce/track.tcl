# $Id: track.tcl,v 3.0.4.1 2000/04/28 15:10:04 carsten Exp $
set_form_variables
# shipment_id
# possibly usca_p

set user_id [ad_verify_and_get_user_id]
set db [ns_db gethandle]

if {$user_id == 0} {
    set return_url "[ns_conn url]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

ec_create_new_session_if_necessary [export_url_vars shipment_id]

ec_log_user_as_user_id_for_this_session

# Make sure this order belongs to the user.
if { [database_to_tcl_string $db "select user_id from ec_orders o, ec_shipments s
where o.order_id = s.order_id
  and s.shipment_id = $shipment_id"] != $user_id } {
    ad_return_error "Invalid Order ID" "Invalid Order ID"
    return
}

set selection [ns_db 1row $db "select to_char(shipment_date, 'MMDDYY') as ship_date_for_fedex, to_char(shipment_date, 'MM/DD/YYYY') as pretty_ship_date, carrier, tracking_number
from ec_shipments
where shipment_id = $shipment_id"]

set_variables_after_query

set carrier_info ""

if { $carrier == "FedEx" } {
    set fedex_url "http://www.fedex.com/cgi-bin/track_it?airbill_list=$tracking_number&kurrent_airbill=$tracking_number&language=english&cntry_code=us&state=0"
    with_catch errmsg {
	set page_from_fedex [ns_httpget $fedex_url]
	regexp {<!-- BEGIN TRACKING INFORMATION -->(.*)<!-- END TRACKING INFORMATION -->} $page_from_fedex match carrier_info
    } {
	set carrier_info "Unable to retrieve data from FedEx."
    }
} elseif { [string match "UPS*" $carrier] } {
    set ups_url "http://wwwapps.ups.com/etracking/tracking.cgi?submit=Track&InquiryNumber1=$tracking_number&TypeOfInquiryNumber=T"
    with_catch errmsg {
	set first_ups_page [ns_httpget $ups_url]
	# UPS needs this magic line1 to get to the more interesting detail page.
	if { ![regexp {NAME="line1" VALUE="([^\"]+)"} $first_ups_page match line1] } {
	    set carrier_info "Unable to parse summary information from UPS."
	} else {
	    set url "http://wwwapps.ups.com/etracking/tracking.cgi"
	    set formvars "InquiryNumber1=$tracking_number&TypeOfInquiryNumber=T&line1=[ns_urlencode $line1]&tdts1=1"
	    set second_ups_page [util_httppost $url $formvars]
	    if { ![regexp {(<TR><TD[^>]*>Tracking Number:.*</TABLE>).*Tracking results provided by UPS} $second_ups_page match ups_info] } {
		set carrier_info "Unable to parse detail data from UPS."
	    } else {
		set carrier_info "<table noborder>$ups_info" 
	    }
	}
    } {
	set carrier_info "Unable to retrieve data from UPS.
    } 
    
}

ad_return_template
