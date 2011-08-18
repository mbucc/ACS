# $Id: add-3.tcl,v 3.0.4.1 2000/04/28 15:08:55 carsten Exp $
set_the_usual_form_variables 

# retailer_id, 
# retailer_name, primary_contact_name, secondary_contact_name,
# primary_contact_info, secondary_contact_info, line1, line2,
# city, usps_abbrev, zip_code, phone, fax, url, country_code, reach,
# nexus_states, financing_policy, return_policy,
# price_guarantee_policy, delivery_policy, installation_policy

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]

# we have to generate audit information
set audit_fields "last_modified, last_modifying_user, modified_ip_address"
set audit_info "sysdate, '$user_id', '[DoubleApos [ns_conn peeraddr]]'"

ns_db dml $db "insert into ec_retailers
(retailer_id, retailer_name, primary_contact_name, secondary_contact_name, primary_contact_info, secondary_contact_info, line1, line2, city, usps_abbrev, zip_code, phone, fax, url, country_code, reach, nexus_states, financing_policy, return_policy, price_guarantee_policy, delivery_policy, installation_policy, $audit_fields)
values 
($retailer_id, '$QQretailer_name', '$QQprimary_contact_name', '$QQsecondary_contact_name', '$QQprimary_contact_info', '$QQsecondary_contact_info', '$QQline1', '$QQline2', '$QQcity', '$QQusps_abbrev', '$QQzip_code', '$QQphone', '$QQfax', '$QQurl', '$QQcountry_code', '$QQreach', '$QQnexus_states', '$QQfinancing_policy', '$QQreturn_policy', '$QQprice_guarantee_policy', '$QQdelivery_policy', '$QQinstallation_policy', $audit_info)
"

ad_returnredirect index.tcl