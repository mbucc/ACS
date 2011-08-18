# $Id: by-order-state-and-time.tcl,v 3.0 2000/02/06 03:18:53 ron Exp $
set_form_variables 0
# possibly view_order_state and/or view_confirmed and/or order_by

if { ![info exists view_order_state] } {
    set view_order_state "reportable"
}
if { ![info exists view_confirmed] } {
    set view_confirmed "all"
}
if { ![info exists order_by] } {
    set order_by "o.order_id"
}

ReturnHeaders

ns_write "[ad_admin_header "Order History"]

<h2>Order History</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "History"]

<hr>

<form method=post action=by-order-state-and-time.tcl>
[export_form_vars view_confirmed order_by]

<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr bgcolor=ececec>
<td align=center><b>Order State</b></td>
<td align=center><b>Confirmed Date</b></td>
</tr>
<tr>
<td align=center><select name=view_order_state>
"

set order_state_list [list [list reportable "reportable (authorized, partially fulfilled, or fulfilled)"] [list in_basket in_basket] [list expired expired] [list confirmed confirmed] [list authorized_plus_avs authorized_plus_avs] [list authorized_minus_avs authorized_minus_avs] [list partially_fulfilled partially_fulfilled] [list fulfilled fulfilled] [list returned returned] [list void void]]

foreach order_state $order_state_list {
    if {[lindex $order_state 0] == $view_order_state} {
	ns_write "<option value=\"[lindex $order_state 0]\" selected>[lindex $order_state 1]"
    } else {
	ns_write "<option value=\"[lindex $order_state 0]\">[lindex $order_state 1]"
    }
}

ns_write "</select>
<input type=submit value=\"Change\">
</td>
<td align=center>
"

set confirmed_list [list [list last_24 "last 24 hrs"] [list last_week "last week"] [list last_month "last month"] [list all all]]

set linked_confirmed_list [list]

foreach confirmed $confirmed_list {
    if {$view_confirmed == [lindex $confirmed 0]} {
	lappend linked_confirmed_list "<b>[lindex $confirmed 1]</b>"
    } else {
	lappend linked_confirmed_list "<a href=\"by-order-state-and-time.tcl?[export_url_vars view_order_state order_by]&view_confirmed=[lindex $confirmed 0]\">[lindex $confirmed 1]</a>"
    }
}

ns_write "\[ [join $linked_confirmed_list " | "] \]

</td></tr></table>

</form>
<blockquote>
"

if { $view_order_state == "reportable" } {
    set order_state_query_bit "and o.order_state in ('authorized_plus_avs','authorized_minus_avs','partially_fulfilled','fulfilled')"
} else {
    set order_state_query_bit "and o.order_state='$view_order_state'"
}

if { $view_confirmed == "last_24" } {
    set confirmed_query_bit "and sysdate-o.confirmed_date <= 1"
} elseif { $view_confirmed == "last_week" } {
    set confirmed_query_bit "and sysdate-o.confirmed_date <= 7"
} elseif { $view_confirmed == "last_month" } {
    set confirmed_query_bit "and months_between(sysdate,o.confirmed_date) <= 1"
} else {
    set confirmed_query_bit ""
}

set link_beginning "by-order-state-and-time.tcl?[export_url_vars view_order_state view_confirmed]"

set table_header "<table>
<tr>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "o.order_id"]\">Order ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "o.confirmed_date"]\">Date Confirmed</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "o.order_state"]\">Order State</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "u.last_name, u.first_names"]\">Customer</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "ec_total_price(o.order_id)"]\">Amount</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "n_items"]\"># of Items</a></b></td>
</tr>"


set db [ns_db gethandle]

set selection [ns_db select $db "select o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id) as price_to_display, o.user_id, u.first_names, u.last_name, count(*) as n_items
from ec_orders o, users u, ec_items i
where o.user_id=u.user_id(+)
and o.order_id=i.order_id
$confirmed_query_bit $order_state_query_bit
group by o.order_id, o.confirmed_date, o.order_state, ec_total_price(o.order_id), o.user_id, u.first_names, u.last_name
order by $order_by
"]

set row_counter 0
while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $row_counter == 0 } {
	ns_write $table_header
    } elseif { $row_counter == 20 } {
	ns_write "</table>
	<p>
	$table_header
	"
	set row_counter 1
    }
    # even rows are white, odd are grey
    if { [expr floor($row_counter/2.)] == [expr $row_counter/2.] } {
	set bgcolor "white"
    } else {
	set bgcolor "ececec"
    }
    ns_write "<tr bgcolor=\"$bgcolor\">
<td><a href=\"one.tcl?[export_url_vars order_id]\">$order_id</a></td>
<td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $confirmed_date]]</td>
<td>$order_state</td>
<td>[ec_decode $last_name "" "&nbsp;" "<a href=\"/admin/users/one.tcl?[export_url_vars user_id]\">$last_name, $first_names</a>"]</td>
<td>[ec_nbsp_if_null [ec_pretty_price $price_to_display]]</td>
<td>$n_items</td></tr>
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