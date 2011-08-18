# $Id: refunds.tcl,v 3.0 2000/02/06 03:19:29 ron Exp $
set_form_variables 0
# possibly view_refund_date and/or order_by

if { ![info exists view_refund_date] } {
    set view_refund_date "all"
}
if { ![info exists order_by] } {
    set order_by "r.refund_id"
}

ReturnHeaders

ns_write "[ad_admin_header "Refund History"]

<h2>Refund History</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "Refund History"]

<hr>

<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr bgcolor=\"ececec\">
<td align=center><b>Refund Date</b></td>
</tr>
<tr>
<td align=center>
"

set refund_date_list [list [list last_24 "last 24 hrs"] [list last_week "last week"] [list last_month "last month"] [list all all]]

set linked_refund_date_list [list]

foreach refund_date $refund_date_list {
    if {$view_refund_date == [lindex $refund_date 0]} {
	lappend linked_refund_date_list "<b>[lindex $refund_date 1]</b>"
    } else {
	lappend linked_refund_date_list "<a href=\"refunds.tcl?[export_url_vars order_by]&view_refund_date=[lindex $refund_date 0]\">[lindex $refund_date 1]</a>"
    }
}

ns_write "\[ [join $linked_refund_date_list " | "] \]

</td></tr></table>

</form>
<blockquote>
"

if { $view_refund_date == "last_24" } {
    set refund_date_query_bit "and sysdate-r.refund_date <= 1"
} elseif { $view_refund_date == "last_week" } {
    set refund_date_query_bit "and sysdate-r.refund_date <= 7"
} elseif { $view_refund_date == "last_month" } {
    set refund_date_query_bit "and months_between(sysdate,r.refund_date) <= 1"
} else {
    set refund_date_query_bit ""
}


set link_beginning "refunds.tcl?[export_url_vars view_refund_date]"

set table_header "<table>
<tr>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "r.refund_id"]\">Refund ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "r.refund_date"]\">Date Refunded</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "r.order_id"]\">Order ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "r.refund_amount"]\">Amount</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "n_items"]\"># of Items</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "u.last_name, u.first_names"]\">By</a></b></td>
</tr>"

set db [ns_db gethandle]

set selection [ns_db select $db "select r.refund_id, r.refund_date, r.order_id, r.refund_amount, r.refunded_by, u.first_names, u.last_name, count(*) as n_items
from ec_refunds r, users u, ec_items i
where r.refunded_by=u.user_id
and i.refund_id=r.refund_id
$refund_date_query_bit
group by r.refund_id, r.refund_date, r.order_id, r.refund_amount, r.refunded_by, u.first_names, u.last_name
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
<td>$refund_id</td>
<td>[util_AnsiDatetoPrettyDate $refund_date]</td>
<td><a href=\"one.tcl?[export_url_vars order_id]\">$order_id</a></td>
<td>[ec_pretty_price $refund_amount]</td>
<td>$n_items</td>
<td><a href=\"/admin/users/one.tcl?user_id=$refunded_by\">$last_name, $first_names</a></td></tr>
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