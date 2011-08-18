# $Id: shipments.tcl,v 3.0 2000/02/06 03:19:33 ron Exp $
set_form_variables 0
# possibly view_carrier and/or view_shipment_date and/or order_by

if { ![info exists view_carrier] } {
    set view_carrier "all"
}
if { ![info exists view_shipment_date] } {
    set view_shipment_date "all"
}
if { ![info exists order_by] } {
    set order_by "s.shipment_id"
}

ReturnHeaders

ns_write "[ad_admin_header "Shipment History"]

<h2>Shipment History</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "Shipment History"]

<hr>

<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr bgcolor=ececec>
<td align=center><b>Carrier</b></td>
<td align=center><b>Shipment Date</b></td>
</tr>
<tr>
<td align=center>
"

set db [ns_db gethandle]

set carrier_list [database_to_tcl_list $db "select unique carrier from ec_shipments where carrier is not null order by carrier"]
set carrier_list [concat "all" $carrier_list]

set linked_carrier_list [list]

foreach carrier $carrier_list {
    if {$view_carrier == $carrier} {
	lappend linked_carrier_list "<b>$carrier</b>"
    } else {
	lappend linked_carrier_list "<a href=\"shipments.tcl?[export_url_vars view_shipment_date order_by]&view_carrier=[ns_urlencode $carrier]\">$carrier</a>"
    }
}

ns_write "\[ [join $linked_carrier_list " | "] \]
</td>
<td align=center>
"

set shipment_date_list [list [list last_24 "last 24 hrs"] [list last_week "last week"] [list last_month "last month"] [list all all]]

set linked_shipment_date_list [list]

foreach shipment_date $shipment_date_list {
    if {$view_shipment_date == [lindex $shipment_date 0]} {
	lappend linked_shipment_date_list "<b>[lindex $shipment_date 1]</b>"
    } else {
	lappend linked_shipment_date_list "<a href=\"shipments.tcl?[export_url_vars view_carrier order_by]&view_shipment_date=[lindex $shipment_date 0]\">[lindex $shipment_date 1]</a>"
    }
}

ns_write "\[ [join $linked_shipment_date_list " | "] \]

</td></tr></table>

</form>
<blockquote>
"

if { $view_carrier == "all" } {
    set carrier_query_bit ""
} else {
    set carrier_query_bit "s.carrier='[DoubleApos $view_carrier]'"
}

if { $view_shipment_date == "last_24" } {
    set shipment_date_query_bit "sysdate-s.shipment_date <= 1"
} elseif { $view_shipment_date == "last_week" } {
    set shipment_date_query_bit "sysdate-s.shipment_date <= 7"
} elseif { $view_shipment_date == "last_month" } {
    set shipment_date_query_bit "months_between(sysdate,s.shipment_date) <= 1"
} else {
    set shipment_date_query_bit ""
}

if { [empty_string_p $carrier_query_bit] && [empty_string_p $shipment_date_query_bit] } {
    set where_clause ""
} elseif { [empty_string_p $carrier_query_bit] } {
    set where_clause "where $shipment_date_query_bit"
} elseif { [empty_string_p $shipment_date_query_bit] } {
    set where_clause "where $carrier_query_bit"
} else {
    set where_clause "where $shipment_date_query_bit and $carrier_query_bit"
}

set link_beginning "shipments.tcl?[export_url_vars view_carrier view_shipment_date]"

set table_header "<table>
<tr>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "s.shipment_id"]\">Shipment ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "s.shipment_date"]\">Date Shipped</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "s.order_id"]\">Order ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "s.carrier"]\">Carrier</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "n_items"]\"># of Items</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "full_or_partial"]\">Full / Partial</a></b></td>
</tr>"


# set selection [ns_db select $db "select s.shipment_id, s.shipment_date, s.order_id, s.carrier, decode((select count(*) from ec_items where order_id=s.order_id),(select count(*) from ec_items where shipment_id=s.shipment_id),'Full','Partial') as full_or_partial, (select count(*) from ec_items where shipment_id=s.shipment_id) as n_items
# from ec_shipments s
# $where_clause
# order by $order_by"]

set selection [ns_db select $db "select s.shipment_id, s.shipment_date, s.order_id, s.carrier, decode(nvl((select count(*) from ec_items where order_id=s.order_id),0),nvl((select count(*) from ec_items where shipment_id=s.shipment_id),0),'Full','Partial') as full_or_partial, nvl((select count(*) from ec_items where shipment_id=s.shipment_id),0) as n_items
from ec_shipments s
$where_clause
order by $order_by"]

set row_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $row_counter == 0 } {
	ns_write $table_header
    }
    # even rows are white, odd are grey
    if { [expr floor($row_counter/2.)] == [expr $row_counter/2.] } {
	set bgcolor "white"
    } else {
	set bgcolor "ececec"
    }
    ns_write "<tr bgcolor=\"$bgcolor\">
<td>$shipment_id</td>
<td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $shipment_date]]</td>
<td><a href=\"one.tcl?[export_url_vars order_id]\">$order_id</a></td>
<td>[ec_nbsp_if_null $carrier]</td>
<td>$n_items</td>
<td>$full_or_partial</td></tr>
    "
    incr row_counter
}


if { $row_counter != 0 } {
    ns_write "</table>"
} else {
    ns_write "<center>None Found</center>"
}

ns_write "</blockquote>

[ad_admin_footer]
"