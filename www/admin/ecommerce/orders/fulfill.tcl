# $Id: fulfill.tcl,v 3.0.4.1 2000/04/28 15:08:44 carsten Exp $
set_the_usual_form_variables
# order_id

# the customer service rep must be logged on
set customer_service_rep [ad_get_user_id]

if {$customer_service_rep == 0} {
    set return_url "[ns_conn url]?[export_entire_form_as_url_vars]"
    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

set db [ns_db gethandle]
set user_id [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]

ReturnHeaders
ns_write "<head>
<title>Order Fulfillment</title>
</head>
<body bgcolor=white text=black>

<h2>Order Fulfillment</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] [list "fulfillment.tcl" "Fulfillment"] "One Order"]

<hr>

<form name=fulfillment_form method=post action=fulfill-2.tcl>
[export_form_vars order_id]

Check off the shipped items:
<blockquote>
[ec_items_for_fulfillment_or_return $db $order_id "t"]
</blockquote>

<p>
<br>
Enter the following if relevant:

<blockquote>
<table>
<tr>
<td>Shipment date (required):</td>
<td>[ad_dateentrywidget shipment_date] [ec_timeentrywidget shipment_date "[ns_localsqltimestamp]"]</td>
</tr>
<tr>
<td>Expected arrival date:</td>
<td>[ad_dateentrywidget expected_arrival_date ""] [ec_timeentrywidget expected_arrival_date ""]</td>
</tr>
<tr>
<td>Carrier</td>
<td>
<!-- the reason these are hardcoded is that we need carrier names to be exactly what we have here if we're going to be able to construct the package tracking pages -->
<select name=carrier>
<option value=\"\">select one
<option value=\"FedEx\">FedEx
<option value=\"UPS Ground\">UPS Ground
<option value=\"UPS Air\">UPS Air
<option value=\"US Priority\">US Priority
<option value=\"USPS\">USPS
</select>

Other:
<input type=text name=carrier_other size=10>
</td>
</tr>
<tr>
<td>Tracking Number</td>
<td><input type=text name=tracking_number size=20></td>
</tr>
</table>
</blockquote>

<center>
<input type=submit value=\"Continue\">
</center>

</form>

[ad_admin_footer]
"
