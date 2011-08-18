# $Id: add.tcl,v 3.0 2000/02/06 03:21:17 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Add a Retailer"]

<h2>Add a Retailer</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Retailers"] "Add Retailer"]

<hr>

<p>

<form method=post action=add-2.tcl>
<table>
<tr>
<td valign=top>Retailer Name</td>
<td valign=top><input type=text name=retailer_name size=30></td>
</tr>
<tr>
<td valign=top>Primary Contact</td>
<td valign=top>

  <table>
  <tr>
  <td valign=top>Name</td>
  <td valign=top><input type=text name=primary_contact_name size=30><br></td>
  </tr>
  <tr>
  <td valign=top>Contact Info</td>
  <td valign=top><textarea wrap name=primary_contact_info rows=4 cols=30></textarea></td>
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
  <td valign=top><input type=text name=secondary_contact_name size=30><br></td>
  </tr>
  <tr>
  <td valign=top>Contact Info</td>
  <td valign=top><textarea wrap name=secondary_contact_info rows=4 cols=30></textarea></td>
  </tr>
  </table>

</td>
</tr>
<tr>
<td valign=top>Address</td>
<td valign=top><input type=text name=line1 size=30><br>
<input type=text name=line2 size=30></td>
</tr>
<tr>
<td valign=top>City</td>
<td valign=top><input type=text name=city size=15>
"

set db [ns_db gethandle]

ns_write "State [state_widget $db]
Zip <input type=text name=zip_code size=5>
</td>
</tr>
<tr>
<td valign=top>Country</td>
<td valign=top>[country_widget $db "us" "country_code" ""]</td>
</tr>
<tr>
<td valign=top>Phone</td>
<td valign=top><input type=text name=phone size=14></td>
</tr>
<tr>
<td valign=top>Fax</td>
<td valign=top><input type=text name=fax size=14></td>
</tr>
<tr>
<td valign=top>URL</td>
<td valign=top><input type=text name=url size=25></td>
</tr>
<tr>
<td valign=top>Reach</td>
<td valign=top>[ec_reach_widget]</td>
</tr>
<tr>
<td valign=top>Nexus States</td>
<td valign=top>[ec_multiple_state_widget $db "" nexus_states]</td>
</tr>
<tr>
<td valign=top>Financing</td>
<td valign=top><textarea wrap name=financing_policy rows=4 cols=50></textarea></td>
</tr>
<tr>
<td valign=top>Return Policy</td>
<td valign=top><textarea wrap name=return_policy rows=4 cols=50></textarea></td>
</tr>
<tr>
<td valign=top>Price Guarantee Policy</td>
<td valign=top><textarea wrap name=price_guarantee_policy rows=4 cols=50></textarea></td>
</tr>
<tr>
<td valign=top>Delivery</td>
<td valign=top><textarea wrap name=delivery_policy rows=4 cols=50></textarea></td>
</tr>
<tr>
<td valign=top>Installation</td>
<td valign=top><textarea wrap name=installation_policy rows=4 cols=50></textarea></td>
</tr>
</table>

<p>

<center>
<input type=submit value=\"Continue\">
</center>
</form>
[ad_admin_footer]
"