# $Id: address-add.tcl,v 3.0 2000/02/06 03:18:52 ron Exp $
set_the_usual_form_variables
# order_id

ReturnHeaders
ns_write "[ad_admin_header "New Shipping Address"]

<h2>New Shipping Address</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "one.tcl?[export_url_vars order_id]" "One Order"] "New Shipping Address"]

<hr>
Please enter a new domestic address or a new international address.  All future shipments for this order will go to this address.

<p>
New domestic address:
"

set db [ns_db gethandle]
set user_name [database_to_tcl_string $db "select first_names || ' ' || last_name from users, ec_orders where ec_orders.user_id=users.user_id and order_id=$order_id"]

ns_write "
<blockquote>
<form method=post action=address-add-2.tcl>
[export_form_vars order_id]
<table>
<tr>
 <td>Name</td>
 <td><input type=text name=attn size=30 value=\"[philg_quote_double_quotes $user_name]\"></td>
</tr>
<tr>
 <td>Address</td>
 <td><input type=text name=line1 size=40></td>
</tr>
<tr>
 <td>2nd line (optional)</td>
 <td><input type=text name=line2 size=40></td>
</tr>
<tr>
 <td>City</font></td>
 <td><input type=text name=city size=20> &nbsp;State [state_widget $db]</td>
</tr>
<tr>
 <td>Zip</td>
 <td><input type=text maxlength=5 name=zip_code size=5></td>
</tr>
<tr>
 <td>Phone</td>
 <td><input type=text name=phone size=20 maxlength=20> <input type=radio name=phone_time value=D CHECKED> day &nbsp;&nbsp;&nbsp;<input type=radio name=phone_time value=E> evening</td>
</tr>
</table>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>
</blockquote>

<p>
New international address:
<p>
<form method=post action=address-add-2.tcl>
[export_form_vars order_id]
<blockquote>
<table>
<tr>
 <td>Name</td>
 <td><input type=text name=attn size=30 value=\"[philg_quote_double_quotes $user_name]\"></td>
</tr>
<tr>
 <td>Address</td>
 <td><input type=text name=line1 size=50></td>
</tr>
<tr>
 <td>2nd line (optional)</td>
 <td><input type=text name=line2 size=50></td>
</tr>
<tr>
 <td>City</font></td>
 <td><input type=text name=city size=20></td>
</tr>
<tr>
 <td>Province or Region</td>
 <td><input type=text name=full_state_name size=15></td>
</tr>
<tr>
 <td>Postal Code</td>
 <td><input type=text maxlength=10 name=zip_code size=10></td>
</tr>
<tr>
 <td>Country</td>
 <td>[ec_country_widget $db ""]</td>
</tr>
<tr>
 <td>Phone</td>
 <td><input type=text name=phone size=20 maxlength=20> <input type=radio name=phone_time value=D CHECKED> day &nbsp;&nbsp;&nbsp;<input type=radio name=phone_time value=E> evening</td>
</tr>
</table>
</blockquote>
<p>
<center>
<input type=submit value=\"Continue\">
</center>
</form>

[ad_admin_footer]
"
