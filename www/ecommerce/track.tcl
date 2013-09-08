#  www/ecommerce/track.tcl
ad_page_contract {
    @param shipment_id The ID of the shipment to track
    @param ucsa_p User session begun or not

    @author
    @creation-date
    @cvs-id track.tcl,v 3.2.2.6 2000/08/18 21:46:37 stevenp Exp
} {
    shipment_id:notnull,naturalnum
    ucsa_p:optional
}

set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    set return_url "[ad_conn url]"
    ad_returnredirect "/register?[export_url_vars return_url]"
    return
}

# user session tracking
set user_session_id [ec_get_user_session_id]

ec_create_new_session_if_necessary [export_url_vars shipment_id]

ec_log_user_as_user_id_for_this_session

# Make sure this order belongs to the user.
if { [db_string assure_order_is_this_user "select user_id from ec_orders o, ec_shipments s
where o.order_id = s.order_id
and s.shipment_id = :shipment_id"] != $user_id } {
    ad_return_error "Invalid Order ID" "Invalid Order ID"
    return
}

db_1row get_order_info "select to_char(shipment_date, 'MMDDYY') as ship_date_for_fedex, to_char(shipment_date, 'MM/DD/YYYY') as pretty_ship_date, carrier, tracking_number
from ec_shipments
where shipment_id = :shipment_id"

set carrier_info ""

if { $carrier == "FedEx" } {
    set fedex_url "http://www.fedex.com/cgi-bin/track_it?airbill_list=$tracking_number&current_airbill=$tracking_number&language=english&cntry_code=us&state=0"
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
db_release_unused_handles

ad_return_template
