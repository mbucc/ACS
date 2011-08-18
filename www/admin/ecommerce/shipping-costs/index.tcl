# $Id: index.tcl,v 3.0 2000/02/06 03:21:33 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Shipping Costs"]

<h2>Shipping Costs</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Shipping Costs"]

<hr>

<h3>Your Current Settings</h3>

<p>
<blockquote>
"
# for audit table
set table_names_and_id_column [list ec_admin_settings ec_admin_settings_audit 1]

set db [ns_db gethandle]
set selection [ns_db 1row $db "select base_shipping_cost, default_shipping_per_item, weight_shipping_cost, add_exp_base_shipping_cost, add_exp_amount_per_item, add_exp_amount_by_weight
from ec_admin_settings"]
set_variables_after_query

ns_write "[ec_shipping_cost_summary $base_shipping_cost $default_shipping_per_item $weight_shipping_cost $add_exp_base_shipping_cost $add_exp_amount_per_item $add_exp_amount_by_weight]

</blockquote>

<p>

<h3>Change Your Settings</h3>

<p>
<blockquote>

All prices are in [ad_parameter Currency ecommerce].  The price should
be written as a decimal number (no special characters like \$).  If a
section is not applicable, just leave it blank.

<p>

It is recommended that you read <a href=\"examples.tcl\">some
examples</a> before you fill in this form.

<p>

<ol>

<form method=post action=edit.tcl>

<b><li>Set the Base Cost:</b>
<input type=text name=base_shipping_cost size=5 value=\"$base_shipping_cost\">

<p>

The Base Cost is the base amount that everybody has to pay regardless of
what they purchase.  Then additional amounts are added, as specified below.

<p>

<b><li>Set the Per-Item Cost:</b>

If the \"Shipping Price\" field of a product is filled in, that will 
override any of the settings below.  Also, you can fill in the
\"Shipping Price - Additional\" field if you want to charge the
customer a lower shipping amount if they order more than one of the
same product.  (If \"Shipping Price - Additional\" is blank, they'll
just be charged \"Shipping Price\" for each item).

<p>

If the \"Shipping Price\" field is blank, charge them by one of
these methods <b>(fill in only one)</b>:

<p>

  <ul>

  <li>Default Amount Per Item:
  <input type=text name=default_shipping_per_item size=5 value=\"$default_shipping_per_item\">

  <p>

  <li>Weight Charge: <input type=text size=5 name=weight_shipping_cost value=\"$weight_shipping_cost\"> [ad_parameter Currency ecommerce]/[ad_parameter WeightUnits ecommerce]

  </ul>

<p>

<b><li>Set the Express Shipping Charges:</b>

<p>
 
Ignore this section if you do not do express shipping.  The amounts you specify below will be <b>added to</b> the amounts you set above if the user elects to have their order express shipped.

<p>

  <ul>

  <li>Additional Base Cost: <input type=text name=add_exp_base_shipping_cost size=5 value=\"$add_exp_base_shipping_cost\">

  <p>

  <li>Additional Amount Per Item: <input type=text name=add_exp_amount_per_item size=5 value=\"$add_exp_amount_per_item\">

  <p>

  <li>Additional Amount by Weight: <input type=text name=add_exp_amount_by_weight size=5 value=\"$add_exp_amount_by_weight\"> [ad_parameter Currency ecommerce]/[ad_parameter WeightUnits ecommerce]

  </ul>

</ol>

<center>
<input type=submit value=\"Submit Changes\">
</center>

</form>

</blockquote>

<h3>Audit Trail</h3>

<ul>
<li><a href=\"/admin/ecommerce/audit-tables.tcl?[export_url_vars table_names_and_id_column]\">Audit Shipping Costs</a>
</ul>

[ad_admin_footer]
"
