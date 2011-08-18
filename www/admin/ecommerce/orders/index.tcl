# $Id: index.tcl,v 3.0 2000/02/06 03:19:13 ron Exp $
ReturnHeaders

ns_write "[ad_admin_header "Orders / Shipments / Refunds"]

<h2>Orders / Shipments / Refunds</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] "Orders / Shipments / Refunds"]

<hr>
"

set db [ns_db gethandle]

ns_write "<ul>"

set selection [ns_db 1row $db "
select 
  sum(one_if_within_n_days(confirmed_date,1)) as n_o_in_last_24_hours,
  sum(one_if_within_n_days(confirmed_date,7)) as n_o_in_last_7_days
from ec_orders_reportable"]
set_variables_after_query

set selection [ns_db 1row $db "
select
  sum(one_if_within_n_days(issue_date,1)) as n_g_in_last_24_hours,
  sum(one_if_within_n_days(issue_date,7)) as n_g_in_last_7_days
from ec_gift_certificates_purchased"]
set_variables_after_query

set selection [ns_db 1row $db "
select
  sum(one_if_within_n_days(issue_date,1)) as n_gi_in_last_24_hours,
  sum(one_if_within_n_days(issue_date,7)) as n_gi_in_last_7_days
from ec_gift_certificates_issued"]
set_variables_after_query

set selection [ns_db 1row $db "
select
  sum(one_if_within_n_days(shipment_date,1)) as n_s_in_last_24_hours,
  sum(one_if_within_n_days(shipment_date,7)) as n_s_in_last_7_days
from ec_shipments"]
set_variables_after_query

set selection [ns_db 1row $db "
select
  sum(one_if_within_n_days(refund_date,1)) as n_r_in_last_24_hours,
  sum(one_if_within_n_days(refund_date,7)) as n_r_in_last_7_days
from ec_refunds"]
set_variables_after_query

set n_standard_to_ship [database_to_tcl_string $db "select count(*) from ec_orders_shippable where shipping_method='standard'"]
set n_express_to_ship [database_to_tcl_string $db "select count(*) from ec_orders_shippable where shipping_method='express'"]


ns_write "
<li><a href=\"by-order-state-and-time.tcl\">Orders</a> <font size=-1>($n_o_in_last_24_hours in last 24 hours; $n_o_in_last_7_days in last 7 days)</font>
<p>
<li><a href=\"fulfillment.tcl\">Order Fulfillment</a> <font size=-1>($n_standard_to_ship order[ec_decode $n_standard_to_ship 1 "" "s"] to be shipped via standard shipping[ec_decode $n_express_to_ship "0" "" ", $n_express_to_ship via express shipping"])</font>
<p>
<li><a href=\"gift-certificates.tcl\">Gift Certificate Purchases</a> <font size=-1>($n_g_in_last_24_hours in last 24 hours; $n_g_in_last_7_days in last 7 days)</font>
<p>
<li><a href=\"gift-certificates-issued.tcl\">Gift Certificates Issued</a> <font size=-1>($n_gi_in_last_24_hours in last 24 hours; $n_gi_in_last_7_days in last 7 days)</font>
<p>
<li><a href=\"shipments.tcl\">Shipments</a> <font size=-1>($n_s_in_last_24_hours in last 24 hours; $n_s_in_last_7_days in last 7 days)</font>
<p>
<li><a href=\"refunds.tcl\">Refunds</a> <font size=-1>($n_r_in_last_24_hours in last 24 hours; $n_r_in_last_7_days in last 7 days)</font>
<p>
<li><a href=\"revenue.tcl\">Financial Reports</a>
<p>
<li>Search for an order:
<blockquote>

<form method=post action=search.tcl>
By Order ID: <input type=text name=order_id_query_string size=10>
</form>

<form method=post action=search.tcl>
By Product Name: <input type=text name=product_name_query_string size=10>
</form>

<form method=post action=search.tcl>
By Customer Last Name: <input type=text name=customer_last_name_query_string size=10>
</form>

</blockquote>
</ul>
[ad_admin_footer]
"
