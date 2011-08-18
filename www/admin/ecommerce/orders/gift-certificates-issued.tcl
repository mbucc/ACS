# $Id: gift-certificates-issued.tcl,v 3.0 2000/02/06 03:19:11 ron Exp $
set_form_variables 0
# possibly view_rep and/or view_issue_date and/or order_by

if { ![info exists view_rep] } {
    set view_rep "all"
}
if { ![info exists view_issue_date] } {
    set view_issue_date "all"
}
if { ![info exists order_by] } {
    set order_by "g.gift_certificate_id"
}

ReturnHeaders

ns_write "[ad_admin_header "Gift Certificate Issue History"]

<h2>Gift Certificate Issue History</h2>

[ad_admin_context_bar [list "../" "Ecommerce"] [list "index.tcl" "Orders"] "Gift Certificate Issue History"]

<hr>

<form method=post action=gift-certificates-issued.tcl>
[export_form_vars view_issue_date order_by]

<table border=0 cellspacing=0 cellpadding=0 width=100%>
<tr bgcolor=ececec>
<td align=center><b>Rep</b></td>
<td align=center><b>Issue Date</b></td>
</tr>
<tr>
<td align=center><select name=view_rep>
<option value=\"all\">All
"

set db [ns_db gethandle]

set selection [ns_db select $db "
SELECT user_id as rep, first_names as rep_first_names, last_name as rep_last_name
  FROM ec_customer_service_reps
  ORDER BY last_name, first_names"]

while { [ns_db getrow $db $selection] } {
    set_variables_after_query
    if { $view_rep == $rep } {
	ns_write "<option value=$rep selected>$rep_last_name, $rep_first_names\n"
    } else {
	ns_write "<option value=$rep>$rep_last_name, $rep_first_names\n"
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
	lappend linked_issue_date_list "<a href=\"gift-certificates-issued.tcl?[export_url_vars view_rep order_by]&view_issue_date=[lindex $issue_date 0]\">[lindex $issue_date 1]</a>"
    }
}

ns_write "\[ [join $linked_issue_date_list " | "] \]

</td></tr></table>

</form>
<blockquote>
"

if { $view_issue_date == "last_24" } {
    set issue_date_query_bit "and sysdate-g.issue_date <= 1"
} elseif { $view_issue_date == "last_week" } {
    set issue_date_query_bit "and sysdate-g.issue_date <= 7"
} elseif { $view_issue_date == "last_month" } {
    set issue_date_query_bit "and months_between(sysdate,g.issue_date) <= 1"
} else {
    set issue_date_query_bit ""
}

if [regexp {^[0-9]+$} $view_rep] {
    set rep_query_bit "and g.issued_by = $view_rep"
} else {
    set rep_query_bit ""
}


set link_beginning "gift-certificates-issued.tcl?[export_url_vars view_rep view_issue_date]"

set table_header "<table>
<tr>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.gift_certificate_id"]\">ID</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.issue_date"]\">Date Issued</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "u.last_name, u.first_names"]\">Issued By</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "r.last_name, r.first_names"]\">Recipient</a></b></td>
<td><b><a href=\"$link_beginning&order_by=[ns_urlencode "g.amount"]\">Amount</a></b></td>
</tr>"

set selection [ns_db select $db "
SELECT g.gift_certificate_id, g.issue_date, g.amount,
       g.issued_by, u.first_names, u.last_name,
       g.user_id as issued_to, r.first_names as issued_to_first_names, r.last_name as issued_to_last_name
from ec_gift_certificates_issued g, users u, users r
where g.issued_by=u.user_id and g.user_id=r.user_id
$issue_date_query_bit $rep_query_bit
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
<td>[ec_decode $last_name "" "&nbsp;" "<a href=\"/admin/users/one.tcl?user_id=$issued_by\">$last_name, $first_names</a>"]</td>
<td>[ec_decode $last_name "" "&nbsp;" "<a href=\"/admin/users/one.tcl?user_id=$issued_to\">$issued_to_last_name, $issued_to_first_names</a>"]</td>
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