# $Id: address-add-2.tcl,v 3.0 2000/02/06 03:18:49 ron Exp $
set_the_usual_form_variables
# order_id, and either:
# attn, line1, line2, city, usps_abbrev, zip_code, phone, phone_time OR
# attn, line1, line2, city, full_state_name, zip_code, country_code, phone, phone_time

if { ![info exists usps_abbrev] } {
    set usps_abbrev ""
}
if { ![info exists full_state_name] } {
    set full_state_name ""
}
if { ![info exists country_code] } {
    set country_code "us"
}

ReturnHeaders
ns_write "[ad_admin_header "Confirm Shipping Address"]

<h2>Confirm Shipping Address</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?[export_url_vars order_id]" "One Order"] "Confirm Shipping Address"]

<hr>
Please confirm new address:
<blockquote>
"
set db [ns_db gethandle]

ns_write "

[ec_display_as_html [ec_pretty_mailing_address_from_args $db $line1 $line2 $city $usps_abbrev $zip_code $country_code $full_state_name $attn $phone $phone_time]]

</blockquote>
<form method=post action=address-add-3.tcl>
[export_entire_form]
<center>
<input type=submit value=\"Confirm\">
</center>
[ad_admin_footer]
"
