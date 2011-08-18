# $Id: gift-certificates.tcl,v 3.0 2000/02/06 03:19:12 ron Exp $
set_form_variables 0
# possibly view_gift_certificate_state and/or view_issue_date and/or order_by

if { ![info exists view_gift_certificate_state] } {
    set view_gift_certificate_state "reportable"
}
if { ![info exists view_issue_date] } {
    set view_issue_date "all"
}
if { ![info exists order_by] } {
    set order_by "g.gift_certificate_id"
}

ReturnHeaders

ns_write "[ad_admin_header "Gift Certificate Purchase History"]

<h2>Gift Certificate Purchase History</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "Gift Certificate Purchase History"]

<hr>

<form method=post action=gift-certificates.tcl>
[export_form_vars view_issue_date order_by]

<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr bgcolor=ececec>
<td align=center><b>Gift Certificate State</b></td>
<td align=center><b>Issue Date</b></td>
</tr>
<tr>
<td align=center><select name=view_gift_certificate_state>
"

set gift_certificate_state_list [list [list reportable "reportable (authorized plus/minus avs)"] [list confirmed confirmed] [list authorized_plus_avs authorized_plus_avs] [list authorized_minus_avs authorized_minus_avs] [list failed_authorization failed_authorization]]

foreach gift_certificate_state $gift_certificate_state_list {
    if {[lindex $gift_certificate_state 0] == $view_gift_certificate_state} {
	ns_write "<option value=\"[lindex $gift_certificate_state 0]\" selected>[lindex $gift_certificate_state 1]"
    } else {
	ns_write "<option value=\"[lindex $gift_certificate_state 0]\">[lindex $gift_certificate_state 1]"
    }
}

ns_write "</select>
<input type=submit value=\"Change\">
</td>
<td align=center>
"

set issue_date_list [list [list last_24 "last 24 hrs"] [list last_week "last week"] [list last_month "last month"] [list all all]]

set linked_issue_date_list [list]

foreach issue_date $issue_date_list {
    if {$view_issue_date == [lindex $issue_date 0]} {
	lappend linked_issue_date_list "<b>[lindex $issue_date 1]</b>"
    } else {
	lappend linked_issue_date_list "<a href=\"gift-certificates.tcl?[export_url_vars view_gift_certificate_state order_by]&view_issue_date=[lindex $issue_date 0]\">[lindex $issue_date 1]</a>"
    }
}

ns_write "\[ [join $linked_issue_date_list " | "] \]

</td></tr></table>

</form>
<blockquote>
"

if { $view_gift_certificate_state == "reportable" } {
    set gift_certificate_state_query_bit "and g.gift_certificate_state in ('authorized_plus_avs','authorized_minus_avs')"
} else {
    set gift_certificate_state_query_bit "and g.gift_certificate_state='$view_gift_certificate_state'"
}

if { $view_issue_date == "last_24" } {
    set issue_date_query_bit "and sysdate-g.issue_date <= 1"
} elseif { $view_issue_date == "last_week" } {
    set issue_date_query_bit "and sysdate-g.issue_date <= 7"
} elseif { $view_issue_date == "last_month" } {
    set issue_date_query_bit "and months_between(sysdate,g.issue_date) <= 1"
} else {
    set issue_date_query_bit ""
}

set link_beginning "gift-certificates.tcl?[export_url_vars view_gift_certificate_state view_issue_date]"

set table_header "<table>
<tr>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.gift_certificate_id"]\">ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.issue_date"]\">Date Issued</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.gift_certificate_state"]\">Gift Certificate State</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "u.last_name, u.first_names"]\">Purchased By</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.recipient_email"]\">Recipient</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.amount"]\">Amount</a></b></td>
</tr>"

set db [ns_db gethandle]

set selection [ns_db select $db "select g.gift_certificate_id, g.issue_date, g.gift_certificate_state, g.recipient_email, g.purchased_by, g.amount, u.first_names, u.last_name
from ec_gift_certificates g, users u
where g.purchased_by=u.user_id
$issue_date_query_bit $gift_certificate_state_query_bit
order by $order_by
"]

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
    ns_write "<tr bgcolor=$bgcolor>
<td><a href=\"gift-certificate.tcl?[export_url_vars gift_certificate_id]\">$gift_certificate_id</a></td>
<td>[ec_nbsp_if_null [util_AnsiDatetoPrettyDate $issue_date]]</td>
<td>$gift_certificate_state</td>
<td>[ec_decode $last_name "" "&nbsp;" "<a href=\"/admin/users/one.tcl?user_id=$purchased_by\">$last_name, $first_names</a>"]</td>
<td>$recipient_email</td>
<td>[ec_pretty_price $amount]</td>
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