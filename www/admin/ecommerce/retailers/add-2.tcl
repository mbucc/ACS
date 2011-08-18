# $Id: add-2.tcl,v 3.0 2000/02/06 03:21:15 ron Exp $
set_the_usual_form_variables
# retailer_name, primary_contact_name, secondary_contact_name,
# primary_contact_info, secondary_contact_info, line1, line2,
# city, usps_abbrev, zip_code, phone, fax, url, country_code, reach,
# nexus_states, financing_policy, return_policy,
# price_guarantee_policy, delivery_policy, installation_policy

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

# I think retailer_name, line1, city, usps_abbrev, zip_code, phone,
# country_code, and reach should be required

set possible_error_list [list [list retailer_name "the name of the retailer"] [list line1 "the address"] [list city "the city"] [list usps_abbrev "the state"] [list zip_code "the zip code"] [list phone "the phone number"] [list country_code "the country"] [list reach "the reach"] ]

set exception_count 0
set exception_text ""

foreach possible_error $possible_error_list {
    if { ![info exists [lindex $possible_error 0]] || [empty_string_p [set [lindex $possible_error 0]]] } {
	incr exception_count
	append exception_text "<li>You forgot to enter [lindex $possible_error 1]."
    }
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

ReturnHeaders
ns_write "[ad_admin_header "Confirm New Retailer"]

<h2>Confirm New Retailer</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Retailers"] "Add Retailer"]

<hr>
<h3>Please confirm that the information below is correct:</h3>

<blockquote>
<table>
<tr>
<td>
Retailer Name:
</td>
<td>
$retailer_name
</td>
</tr>
<tr>
<td>
Primary Contact:
</td>
<td>
$primary_contact_name<br>
[bboard_convert_plaintext_to_html $primary_contact_info]
</td>
</tr>
<tr>
<td>
Secondary Contact:
</td>
<td>
$secondary_contact_name<br>
[bboard_convert_plaintext_to_html $secondary_contact_info]
</td>
</tr>
<tr>
<td>
Address
</td>
<td>
"
set db [ns_db gethandle]
ns_write "[bboard_convert_plaintext_to_html [ad_pretty_mailing_address_from_args $db $line1 $line2 $city $usps_abbrev $zip_code $country_code]]
</td>
</tr>
<tr>
<td>
Phone
</td>
<td>
$phone
</td>
</tr>
<tr>
<td>
Fax
</td>
<td>
$fax
</td>
</tr>
<tr>
<td>
URL
</td>
<td><a href=\"$url\">$url</a></td>
</tr>
<tr>
<td>
Reach
</td>
<td>
$reach
</td>
</tr>
<tr>
<td>
Nexus States
</td>
<td>
$nexus_states
</td>
</tr>
<tr>
<td>
Financing
</td>
<td>
[bboard_convert_plaintext_to_html $financing_policy]
</td>
</tr>
<tr>
<td>
Return Policy
</td>
<td>
[bboard_convert_plaintext_to_html $return_policy]
</td>
</tr>
<tr>
<td>
Price Guarantee Policy
</td>
<td>
[bboard_convert_plaintext_to_html $price_guarantee_policy]
</td>
</tr>
<tr>
<td>
Delivery
</td>
<td>
[bboard_convert_plaintext_to_html $delivery_policy]
</td>
</tr>
<tr>
<td>
Installation
</td>
<td>
[bboard_convert_plaintext_to_html $installation_policy]
</td>
</tr>
</table>
</blockquote>

<form method=post action=add-3.tcl>
"

set retailer_id [database_to_tcl_string $db "select ec_retailer_sequence.nextval from dual"]

ns_write "[export_form_vars retailer_id retailer_name primary_contact_name secondary_contact_name primary_contact_info secondary_contact_info line1 line2 city usps_abbrev zip_code phone fax url country_code reach nexus_states financing_policy return_policy price_guarantee_policy delivery_policy installation_policy]

<center>
<input type=submit value=\"Confirm\">
</center>
</form>

[ad_admin_footer]
"

