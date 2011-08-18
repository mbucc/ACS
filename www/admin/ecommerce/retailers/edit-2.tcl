# $Id: edit-2.tcl,v 3.0.4.1 2000/04/28 15:08:55 carsten Exp $
set_the_usual_form_variables 

# retailer_id, 
# retailer_name, primary_contact_name, secondary_contact_name,
# primary_contact_info, secondary_contact_info, line1, line2,
# city, usps_abbrev, zip_code, phone, fax, url, country_code, reach,
# nexus_states, financing_policy, return_policy,
# price_guarantee_policy, delivery_policy, installation_policy,

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set audit_update "last_modified=sysdate, last_modifying_user='$user_id', modified_ip_address='[DoubleApos [ns_conn peeraddr]]'"

# nexus_states is a select multiple, so deal with that separately
set form [ns_getform]
set form_size [ns_set size $form]
set form_counter 0

set nexus_states [list]
while { $form_counter < $form_size} {
    if { [ns_set key $form $form_counter] == "nexus_states" } {
	lappend nexus_states [ns_set value $form $form_counter]
    }
    incr form_counter
}

set db [ns_db gethandle]

ns_db dml $db "update ec_retailers
set retailer_name='$QQretailer_name', primary_contact_name='$QQprimary_contact_name', secondary_contact_name='$QQsecondary_contact_name', primary_contact_info='$QQprimary_contact_info', secondary_contact_info='$QQsecondary_contact_info', line1='$QQline1', line2='$QQline2', city='$QQcity', usps_abbrev='$QQusps_abbrev', zip_code='$QQzip_code', phone='$QQphone', fax='$QQfax', url='$QQurl', country_code='$QQcountry_code', reach='$QQreach', nexus_states='$nexus_states', financing_policy='$QQfinancing_policy', return_policy='$QQreturn_policy', price_guarantee_policy='$QQprice_guarantee_policy', delivery_policy='$QQdelivery_policy', installation_policy='$QQinstallation_policy', $audit_update
where retailer_id=$retailer_id
"

ad_returnredirect index.tcl