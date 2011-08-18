# $Id: edit.tcl,v 3.0 2000/02/06 03:21:20 ron Exp $
set_the_usual_form_variables
# retailer_id

ReturnHeaders

ns_write "[ad_admin_header "Edit Retailer"]

<h2>Edit Retailer</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Retailers"] "Edit Retailer"]

<hr>

<p>
"

set db [ns_db gethandle]
set selection [ns_db 1row $db "select * from ec_retailers where retailer_id=$retailer_id"]
set_variables_after_query

ns_write "<form method=post action=edit-2.tcl>
[export_form_vars retailer_id]
<table>
<tr>
<td valign=top>Retailer Name</td>
<td valign=top><input type=text name=retailer_name size=30 value=\"[philg_quote_double_quotes $retailer_name]\"></td>
</tr>
<tr>
<td valign=top>Primary Contact</td>
<td valign=top>

  <table>
  <tr>
  <td valign=top>Name</td>
  <td valign=top><input type=text name=primary_contact_name size=30 value=\"[philg_quote_double_quotes $primary_contact_name]\"><br></td>
  </tr>
  <tr>
  <td valign=top>Contact Info</td>
  <td valign=top><textarea wrap name=primary_contact_info rows=4 cols=30>$primary_contact_info</textarea></td>
  </tr>
  </table>

</td>
</tr>
<tr>
<td valign=top>Secondary Contact</td>
<td valign=top>

  <table>
  <tr>
  <td valign=top>Name</td>
  <td valign=top><input type=text name=secondary_contact_name size=30 value=\"[philg_quote_double_quotes $secondary_contact_name]\"><br></td>
  </tr>
  <tr>
  <td valign=top>Contact Info</td>
  <td valign=top><textarea wrap name=secondary_contact_info rows=4 cols=30>$secondary_contact_info</textarea></td>
  </tr>
  </table>

</td>
</tr>
<tr>
<td valign=top>Address</td>
<td valign=top><input type=text name=line1 size=30 value=\"[philg_quote_double_quotes $line1]\"><br>
<input type=text name=line2 size=30 value=\"[philg_quote_double_quotes $line2]\"></td>
</tr>
<tr>
<td valign=top>City</td>
<td valign=top><input type=text name=city size=15 value=\"[philg_quote_double_quotes $city]\">
State [state_widget $db $usps_abbrev]
Zip <input type=text name=zip_code size=5 value=\"[philg_quote_double_quotes $zip_code]\">
</td>
</tr>
<tr>
<td valign=top>Country</td>
<td valign=top>[country_widget $db "$country_code" "country_code" ""]</td>
</tr>
<tr>
<td valign=top>Phone</td>
<td valign=top><input type=text name=phone size=14 value=\"[philg_quote_double_quotes $phone]\"></td>
</tr>
<tr>
<td valign=top>Fax</td>
<td valign=top><input type=text name=fax size=14 value=\"[philg_quote_double_quotes $fax]\"></td>
</tr>
<tr>
<td valign=top>URL</td>
<td valign=top><input type=text name=url size=25 value=\"[philg_quote_double_quotes $url]\"></td>
</tr>
<tr>
<td valign=top>Reach</td>
<td valign=top>[ec_reach_widget $reach]</td>
</tr>
<tr>
<td valign=top>Nexus States</td>
<td valign=top>[ec_multiple_state_widget $db "$nexus_states" nexus_states]</td>
</tr>
<tr>
<td valign=top>Financing</td>
<td valign=top><textarea wrap name=financing_policy rows=4 cols=50>$financing_policy</textarea></td>
</tr>
<tr>
<td valign=top>Return Policy</td>
<td valign=top><textarea wrap name=return_policy rows=4 cols=50>$return_policy</textarea></td>
</tr>
<tr>
<td valign=top>Price Guarantee Policy</td>
<td valign=top><textarea wrap name=price_guarantee_policy rows=4 cols=50>$price_guarantee_policy</textarea></td>
</tr>
<tr>
<td valign=top>Delivery</td>
<td valign=top><textarea wrap name=delivery_policy rows=4 cols=50>$delivery_policy</textarea></td>
</tr>
<tr>
<td valign=top>Installation</td>
<td valign=top><textarea wrap name=installation_policy rows=4 cols=50>$installation_policy</textarea></td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Continue\">
</center>
</form>
[ad_admin_footer]
"