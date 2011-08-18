# $Id: one.tcl,v 3.0 2000/02/06 03:21:22 ron Exp $
set_the_usual_form_variables
# retailer_id

set db [ns_db gethandle]
set selection [ns_db 1row $db "select * from ec_retailers where retailer_id=$retailer_id"]
set_variables_after_query

ReturnHeaders
ns_write "[ad_admin_header "$retailer_name"]

<h2>$retailer_name</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Retailers"] "One Retailer"]

<hr>
<h3>Current Information</h3>

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
[ec_display_as_html [ad_pretty_mailing_address_from_args $db $line1 $line2 $city $usps_abbrev $zip_code $country_code]]
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
[ec_display_as_html $financing_policy]
</td>
</tr>
<tr>
<td>
Return Policy
</td>
<td>
[ec_display_as_html $return_policy]
</td>
</tr>
<tr>
<td>
Price Guarantee Policy
</td>
<td>
[ec_display_as_html $price_guarantee_policy]
</td>
</tr>
<tr>
<td>
Delivery
</td>
<td>
[ec_display_as_html $delivery_policy]
</td>
</tr>
<tr>
<td>
Installation
</td>
<td>
[ec_display_as_html $installation_policy]
</td>
</tr>
</table>
</blockquote>
"
ns_write "<h3>Actions</h3>
<ul>
<li><a href=\"edit.tcl?retailer_id=$retailer_id\">Edit</a>
"

# Set audit variables
# audit_name, id, id_column, return_url, audit_tables, main_tables
set audit_name "$retailer_name"
set id $retailer_id
set id_column "retailer_id"
set return_url "one.tcl?[export_url_vars retailer_id]"
set audit_tables [list ec_retailers_audit]
set main_tables [list ec_retailers]

ns_write "<li><a href=\"audit.tcl?[export_url_vars audit_name id id_column return_url audit_tables main_tables]\">Audit Trail</a>

</ul>

[ad_admin_footer]
"

