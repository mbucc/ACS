<ec_header>Completing Your Order</ec_header>

<ec_header_image></ec_header_image><br clear=all>

<h2>Completing Your Order</h2>

<ol>

<b><li>Check your order.</b>

<p>

Please verify that the items and quantities shown below are correct. Put a 0 (zero) in the
Quantity field to remove a particular item from your order. 

<form method=post action=<%= "\"$form_action\"" %>>

<table>
<tr>
 <td>Quantity</td>
 <td> </td>
</tr>
<%= $rows_of_items %>
</table>

<p>

<%= $shipping_options %>

</ol>

<center>
<input type=submit value="Continue">
</center>

</form>

<ec_footer></ec_footer>
